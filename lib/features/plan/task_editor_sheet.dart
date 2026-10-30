import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/app_database.dart';
import '../../core/data/enums.dart';
import '../../core/data/settings/settings_provider.dart';
import '../../core/data/task_repository.dart';
import '../../core/notifications/notification_providers.dart';
import '../../core/notifications/reminder_scheduler.dart';
import '../../core/notifications/reminder_status.dart';
import '../../core/utils/clock.dart';
import '../../core/utils/current_day.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/format.dart';
import '../../design_system/design_system.dart';
import 'task_actions.dart';
import '../../l10n/locale_providers.dart';
import 'reminder_defaults.dart';
import 'reminder_permission.dart';
import 'task_labels.dart';

/// 打开新建（task 为空）或编辑任务的底部弹层。
/// [dueToday]：新建时默认日期设为今天（从今天页进入时）。
Future<void> showTaskEditor(
  BuildContext context, {
  Task? task,
  bool dueToday = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => TaskEditorSheet(task: task, dueToday: dueToday),
  );
}

enum _DueChoice { none, today, tomorrow, other }

class TaskEditorSheet extends ConsumerStatefulWidget {
  const TaskEditorSheet({super.key, this.task, this.dueToday = false});

  final Task? task;
  final bool dueToday;

  @override
  ConsumerState<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends ConsumerState<TaskEditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _note;
  late Priority _priority;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  DateTime? _reminderAt;
  late RepeatRule _repeat;
  bool _saving = false;

  bool get _isNew => widget.task == null;

  bool get _isDesktop => switch (Theme.of(context).platform) {
    TargetPlatform.windows ||
    TargetPlatform.macOS ||
    TargetPlatform.linux => true,
    _ => false,
  };

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _title = TextEditingController(text: t?.title ?? '');
    _note = TextEditingController(text: t?.note ?? '');
    _priority = t?.priority ?? Priority.medium;
    if (t?.dueAt != null) {
      _dueDate = startOfDay(t!.dueAt!);
      if (t.dueHasTime) _dueTime = TimeOfDay.fromDateTime(t.dueAt!);
    } else if (t == null && widget.dueToday) {
      _dueDate = ref.read(currentDayProvider);
    }
    _reminderAt = t?.reminderAt;
    _repeat = t?.reminderRepeat ?? RepeatRule.none;
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  DateTime get _today => ref.read(currentDayProvider);

  _DueChoice get _dueChoice {
    final d = _dueDate;
    if (d == null) return _DueChoice.none;
    if (d == _today) return _DueChoice.today;
    if (d == nextDay(_today)) return _DueChoice.tomorrow;
    return _DueChoice.other;
  }

  Future<DateTime?> _pickDate(DateTime initial) {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initial) {
    return showTimePicker(
      context: context,
      initialTime: initial,
      // 手机用表盘、桌面用输入框，不显示切换图标
      // 12 / 24 小时制跟随手机系统设置（MediaQuery.alwaysUse24HourFormat）
      initialEntryMode: _isDesktop
          ? TimePickerEntryMode.inputOnly
          : TimePickerEntryMode.dialOnly,
    );
  }

  Future<void> _onDueChoice(_DueChoice c) async {
    switch (c) {
      case _DueChoice.none:
        setState(() {
          _dueDate = null;
          _dueTime = null;
        });
      case _DueChoice.today:
        setState(() => _dueDate = _today);
      case _DueChoice.tomorrow:
        setState(() => _dueDate = nextDay(_today));
      case _DueChoice.other:
        final picked = await _pickDate(_dueDate ?? _today);
        if (picked != null) setState(() => _dueDate = startOfDay(picked));
    }
  }

  Future<void> _editDueTime() async {
    final picked = await _pickTime(
      _dueTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _dueDate ??= _today;
        _dueTime = picked;
      });
    }
  }

  /// 默认提醒时间（含"新建提醒时默认提前"设置），规则见 reminder_defaults.dart
  DateTime _defaultReminder() {
    return defaultReminderTime(
      dueDate: _dueDate,
      dueHour: _dueTime?.hour,
      dueMinute: _dueTime?.minute,
      now: ref.read(clockProvider).now(),
      leadMinutes: ref.read(settingsProvider).reminderLead.minutes,
    );
  }

  Future<void> _editReminderTime() async {
    final current = _reminderAt ?? _defaultReminder();
    final picked = await _pickTime(TimeOfDay.fromDateTime(current));
    if (picked == null) return;
    setState(() {
      _reminderAt = DateTime(
        current.year,
        current.month,
        current.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  /// 新加提醒：先选时间，取消选择就不加
  Future<void> _addReminder() async {
    final initial = _defaultReminder();
    final picked = await _pickTime(TimeOfDay.fromDateTime(initial));
    if (picked == null) return;
    setState(() {
      _reminderAt = DateTime(
        initial.year,
        initial.month,
        initial.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _editReminderDate() async {
    final current = _reminderAt ?? _defaultReminder();
    final picked = await _pickDate(startOfDay(current));
    if (picked == null) return;
    setState(() {
      _reminderAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        current.hour,
        current.minute,
      );
    });
  }

  TaskDraft _draft() {
    final d = _dueDate;
    final t = _dueTime;
    return TaskDraft(
      title: _title.text.trim(),
      note: _note.text,
      dueAt: d == null
          ? null
          : DateTime(d.year, d.month, d.day, t?.hour ?? 0, t?.minute ?? 0),
      dueHasTime: t != null,
      priority: _priority,
      reminderAt: _reminderAt,
      reminderRepeat: _repeat,
    );
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _saving) return;
    setState(() => _saving = true);
    // 第一个 await 之前取好所有依赖：权限框弹出期间弹层可能被关掉
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l10n = context.l10n;
    final scheduler = ref.read(reminderSchedulerProvider);
    final actions = ref.read(taskActionsProvider);
    final draft = _draft();
    final hasReminder = draft.reminderAt != null;
    try {
      // 第一次设提醒时在这里申请通知权限
      final granted = hasReminder
          ? await ensureNotificationPermission(scheduler)
          : true;
      if (hasReminder && mounted) ref.invalidate(reminderStatusProvider);

      final ScheduleMode? mode;
      if (_isNew) {
        (_, mode) = await actions.create(draft);
      } else {
        (_, mode) = await actions.update(widget.task!.id, draft);
      }
      if (hasReminder) {
        showReminderOutcome(
          messenger,
          permissionGranted: granted,
          mode: mode,
          openExactSettings: scheduler.requestExactAlarmPermission,
          l10n: l10n,
        );
      }
      if (mounted) navigator.pop();
    } catch (e) {
      debugPrint('保存任务失败：$e');
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.taskEditorSaveFailed)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showGeoConfirm(
      context,
      message: context.l10n.taskEditorDeleteConfirm(widget.task!.title),
      confirmLabel: context.l10n.commonDelete,
      cancelLabel: context.l10n.commonCancel,
      destructive: true,
    );
    if (!ok) return;
    await ref.read(taskActionsProvider).delete(widget.task!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final dates = AppDateFormat.of(context);
    final today = ref.watch(currentDayProvider);
    final now = ref.read(clockProvider).now();
    final reminder = _reminderAt;
    final reminderPast =
        reminder != null &&
        _repeat == RepeatRule.none &&
        !reminder.isAfter(now);
    final status = reminder == null
        ? null
        : ref.watch(reminderStatusProvider).value;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, Space.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isNew ? l10n.taskEditorNewTitle : l10n.taskEditorEditTitle,
                    style: context.text.small,
                  ),
                ),
                GeoIconButton(
                  glyph: GeoGlyph.close,
                  semanticLabel: l10n.commonClose,
                  color: colors.muted,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            TextField(
              controller: _title,
              autofocus: _isNew,
              maxLength: 200,
              style: context.text.body,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                hintText: l10n.taskEditorTitleHint,
                counterText: '',
              ),
            ),
            const SizedBox(height: Space.s),
            TextField(
              controller: _note,
              minLines: 1,
              maxLines: 4,
              style: context.text.small.copyWith(color: colors.ink),
              decoration: InputDecoration(
                hintText: l10n.taskEditorNoteHint,
                hintStyle: context.text.small,
              ),
            ),
            _Label(l10n.taskEditorPriorityLabel),
            GeoChoice<Priority>(
              value: _priority,
              onChanged: (p) => setState(() => _priority = p),
              options: [
                for (final p in Priority.values)
                  GeoChoiceOption(
                    value: p,
                    label: priorityLabel(l10n, p),
                    leading: SizedBox.square(
                      dimension: Sizes.glyphInline,
                      child: CustomPaint(
                        painter: TaskSquarePainter(
                          fill: 0,
                          strokeWidth: strokeForPriority(p),
                          outline: colors.ink,
                          fillColor: colors.accent,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            _Label(l10n.taskEditorDateLabel),
            GeoChoice<_DueChoice>(
              value: _dueChoice,
              onChanged: _onDueChoice,
              options: [
                GeoChoiceOption(
                  value: _DueChoice.none,
                  label: l10n.taskEditorDateNone,
                ),
                GeoChoiceOption(
                  value: _DueChoice.today,
                  label: l10n.taskEditorDateToday,
                ),
                GeoChoiceOption(
                  value: _DueChoice.tomorrow,
                  label: l10n.taskEditorDateTomorrow,
                ),
                GeoChoiceOption(
                  value: _DueChoice.other,
                  label: _dueChoice == _DueChoice.other
                      ? dates.date(_dueDate!, today: today)
                      : l10n.taskEditorDatePick,
                ),
              ],
            ),
            if (_dueDate != null)
              Row(
                children: [
                  GeoButton(
                    label: _dueTime == null
                        ? l10n.taskEditorAddTime
                        : dates.time(_withTime(today, _dueTime!)),
                    style: GeoButtonStyle.text,
                    onPressed: _editDueTime,
                  ),
                  if (_dueTime != null)
                    GeoIconButton(
                      glyph: GeoGlyph.close,
                      semanticLabel: l10n.taskEditorClearTime,
                      color: colors.muted,
                      onPressed: () => setState(() => _dueTime = null),
                    ),
                ],
              ),
            _Label(l10n.taskEditorReminderLabel),
            if (reminder == null)
              Align(
                alignment: Alignment.centerLeft,
                child: GeoButton(
                  label: l10n.taskEditorAddReminder,
                  style: GeoButtonStyle.text,
                  onPressed: _addReminder,
                ),
              )
            else ...[
              Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _editReminderTime,
                    child: SizedBox(
                      height: Sizes.tapTarget,
                      child: Center(
                        child: ReminderMark(
                          label: dates.time(reminder),
                          semanticLabel: l10n.reminderSemantics(
                            dates.time(reminder),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.m),
                  // 按钮占满剩余宽度、靠左对齐：长文字（Every Wednesday）在这里换行，而不是被拆成字母
                  Expanded(
                    child: _repeat == RepeatRule.daily
                        ? const SizedBox.shrink()
                        : Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: GeoButton(
                              label: _repeat == RepeatRule.weekly
                                  ? l10n.repeatEveryWeekday(weekdayKey(reminder))
                                  : dates.relative(reminder, today),
                              style: GeoButtonStyle.text,
                              onPressed: _editReminderDate,
                            ),
                          ),
                  ),
                  GeoIconButton(
                    glyph: GeoGlyph.close,
                    semanticLabel: l10n.taskEditorRemoveReminder,
                    color: colors.muted,
                    onPressed: () => setState(() {
                      _reminderAt = null;
                      _repeat = RepeatRule.none;
                    }),
                  ),
                ],
              ),
              GeoChoice<RepeatRule>(
                value: _repeat,
                onChanged: (r) => setState(() => _repeat = r),
                options: [
                  GeoChoiceOption(
                    value: RepeatRule.none,
                    label: l10n.repeatNone,
                  ),
                  GeoChoiceOption(
                    value: RepeatRule.daily,
                    label: l10n.repeatDaily,
                  ),
                  GeoChoiceOption(
                    value: RepeatRule.weekly,
                    label: l10n.repeatWeekly,
                  ),
                ],
              ),
              if (reminderPast) _Hint(l10n.taskEditorHintPast),
              if (_repeat == RepeatRule.none &&
                  widget.task?.completedAt != null)
                _Hint(l10n.taskEditorHintCompleted),
              if (status?.supported == false)
                _Hint(l10n.taskEditorHintUnsupported),
              if (status?.exactMissing ?? false)
                _Hint(
                  l10n.taskEditorHintNoExact,
                  action: l10n.commonTurnOn,
                  onAction: ref
                      .read(reminderSchedulerProvider)
                      .requestExactAlarmPermission,
                ),
            ],
            const SizedBox(height: Space.l),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_isNew)
                  const SizedBox.shrink()
                else
                  Flexible(
                    child: GeoButton(
                      label: l10n.commonDelete,
                      style: GeoButtonStyle.text,
                      destructive: true,
                      onPressed: _delete,
                    ),
                  ),
                const SizedBox(width: Space.m),
                Flexible(
                  child: GeoButton(
                    label: l10n.taskEditorSave,
                    style: GeoButtonStyle.primary,
                    onPressed: _title.text.trim().isEmpty || _saving
                        ? null
                        : _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Space.l, bottom: Space.xs),
      child: Text(text, style: context.text.small),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text, {this.action, this.onAction});

  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Space.s),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: context.text.small.copyWith(color: context.colors.danger),
            ),
          ),
          if (action != null)
            GeoButton(
              label: action!,
              style: GeoButtonStyle.text,
              onPressed: onAction,
            ),
        ],
      ),
    );
  }
}

DateTime _withTime(DateTime day, TimeOfDay t) =>
    DateTime(day.year, day.month, day.day, t.hour, t.minute);
