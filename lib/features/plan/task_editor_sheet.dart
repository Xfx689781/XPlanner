import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/app_database.dart';
import '../../core/data/enums.dart';
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
import 'reminder_permission.dart';
import 'task_labels.dart';

/// 打开新建（task 为空）或编辑任务的底部弹层。
/// [dueToday]：新建时默认日期设为今天（从今天页进入时）。
Future<void> showTaskEditor(BuildContext context, {Task? task, bool dueToday = false}) {
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
    );
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initial) {
    return showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
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
    final picked = await _pickTime(_dueTime ?? const TimeOfDay(hour: 9, minute: 0));
    if (picked != null) {
      setState(() {
        _dueDate ??= _today;
        _dueTime = picked;
      });
    }
  }

  /// 默认提醒：有日期时间就用它；否则下一个整点（日期取任务日期或今天）。
  DateTime _defaultReminder() {
    final due = _dueDate;
    final t = _dueTime;
    if (due != null && t != null) {
      return DateTime(due.year, due.month, due.day, t.hour, t.minute);
    }
    final now = ref.read(clockProvider).now();
    final base = due ?? _today;
    final hour = due == null || due == _today ? now.hour + 1 : 9;
    return DateTime(base.year, base.month, base.day, hour);
  }

  Future<void> _editReminderTime() async {
    final current = _reminderAt ?? _defaultReminder();
    final picked = await _pickTime(TimeOfDay.fromDateTime(current));
    if (picked == null) return;
    setState(() {
      _reminderAt = DateTime(current.year, current.month, current.day, picked.hour, picked.minute);
    });
  }

  /// 新加提醒：先选时间，取消选择就不加
  Future<void> _addReminder() async {
    final initial = _defaultReminder();
    final picked = await _pickTime(TimeOfDay.fromDateTime(initial));
    if (picked == null) return;
    setState(() {
      _reminderAt = DateTime(initial.year, initial.month, initial.day, picked.hour, picked.minute);
    });
  }

  Future<void> _editReminderDate() async {
    final current = _reminderAt ?? _defaultReminder();
    final picked = await _pickDate(startOfDay(current));
    if (picked == null) return;
    setState(() {
      _reminderAt = DateTime(picked.year, picked.month, picked.day, current.hour, current.minute);
    });
  }

  TaskDraft _draft() {
    final d = _dueDate;
    final t = _dueTime;
    return TaskDraft(
      title: _title.text.trim(),
      note: _note.text,
      dueAt: d == null ? null : DateTime(d.year, d.month, d.day, t?.hour ?? 0, t?.minute ?? 0),
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
    final scheduler = ref.read(reminderSchedulerProvider);
    final actions = ref.read(taskActionsProvider);
    final draft = _draft();
    final hasReminder = draft.reminderAt != null;
    try {
      // 第一次设提醒时在这里申请通知权限
      final granted = hasReminder ? await ensureNotificationPermission(scheduler) : true;
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
        );
      }
      if (mounted) navigator.pop();
    } catch (e) {
      debugPrint('保存任务失败：$e');
      messenger.showSnackBar(const SnackBar(content: Text('保存失败，请重试')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showGeoConfirm(
      context,
      message: '删除「${widget.task!.title}」？它的提醒也会取消。',
      confirmLabel: '删除',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(taskActionsProvider).delete(widget.task!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final today = ref.watch(currentDayProvider);
    final now = ref.read(clockProvider).now();
    final reminder = _reminderAt;
    final reminderPast = reminder != null && _repeat == RepeatRule.none && !reminder.isAfter(now);
    final status = reminder == null ? null : ref.watch(reminderStatusProvider).value;

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
                Expanded(child: Text(_isNew ? '新任务' : '编辑任务', style: context.text.small)),
                GeoIconButton(
                  glyph: GeoGlyph.close,
                  semanticLabel: '关闭',
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
              decoration: const InputDecoration(hintText: '要做什么', counterText: ''),
            ),
            const SizedBox(height: Space.s),
            TextField(
              controller: _note,
              minLines: 1,
              maxLines: 4,
              style: context.text.small.copyWith(color: colors.ink),
              decoration: InputDecoration(
                hintText: '备注（可选）',
                hintStyle: context.text.small,
              ),
            ),
            _Label('优先级'),
            GeoChoice<Priority>(
              value: _priority,
              onChanged: (p) => setState(() => _priority = p),
              options: [
                for (final p in Priority.values)
                  GeoChoiceOption(
                    value: p,
                    label: priorityLabel(p),
                    leading: SizedBox.square(
                      dimension: FontSizes.body,
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
            _Label('日期'),
            GeoChoice<_DueChoice>(
              value: _dueChoice,
              onChanged: _onDueChoice,
              options: [
                const GeoChoiceOption(value: _DueChoice.none, label: '无'),
                const GeoChoiceOption(value: _DueChoice.today, label: '今天'),
                const GeoChoiceOption(value: _DueChoice.tomorrow, label: '明天'),
                GeoChoiceOption(
                  value: _DueChoice.other,
                  label: _dueChoice == _DueChoice.other
                      ? formatDate(_dueDate!, today: today)
                      : '选日期',
                ),
              ],
            ),
            if (_dueDate != null)
              Row(
                children: [
                  GeoButton(
                    label: _dueTime == null ? '+ 时间' : _dueTime!.format24(),
                    style: GeoButtonStyle.text,
                    onPressed: _editDueTime,
                  ),
                  if (_dueTime != null)
                    GeoIconButton(
                      glyph: GeoGlyph.close,
                      semanticLabel: '清除时间',
                      color: colors.muted,
                      onPressed: () => setState(() => _dueTime = null),
                    ),
                ],
              ),
            _Label('提醒'),
            if (reminder == null)
              Align(
                alignment: Alignment.centerLeft,
                child: GeoButton(
                  label: '+ 添加提醒',
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
                      child: Center(child: ReminderMark(label: formatTime(reminder))),
                    ),
                  ),
                  const SizedBox(width: Space.m),
                  if (_repeat != RepeatRule.daily)
                    GeoButton(
                      label: _repeat == RepeatRule.weekly
                          ? '每${weekdayLabel(reminder)}'
                          : formatRelativeDate(reminder, today),
                      style: GeoButtonStyle.text,
                      onPressed: _editReminderDate,
                    ),
                  const Spacer(),
                  GeoIconButton(
                    glyph: GeoGlyph.close,
                    semanticLabel: '取消提醒',
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
                options: const [
                  GeoChoiceOption(value: RepeatRule.none, label: '不重复'),
                  GeoChoiceOption(value: RepeatRule.daily, label: '每天'),
                  GeoChoiceOption(value: RepeatRule.weekly, label: '每周'),
                ],
              ),
              if (reminderPast)
                _Hint('这个时间已经过去，不会提醒'),
              if (_repeat == RepeatRule.none && widget.task?.completedAt != null)
                _Hint('这个任务已完成，不会提醒；取消完成后才会提醒'),
              if (status?.supported == false)
                _Hint('这个平台暂不支持提醒，会在手机上生效'),
              if (status?.exactMissing ?? false)
                _Hint(
                  '没有「闹钟和提醒」权限，提醒可能晚几分钟',
                  action: '去开启',
                  onAction: ref.read(reminderSchedulerProvider).requestExactAlarmPermission,
                ),
            ],
            const SizedBox(height: Space.l),
            Row(
              children: [
                if (!_isNew)
                  GeoButton(
                    label: '删除',
                    style: GeoButtonStyle.text,
                    destructive: true,
                    onPressed: _delete,
                  ),
                const Spacer(),
                GeoButton(
                  label: '保存',
                  style: GeoButtonStyle.primary,
                  onPressed: _title.text.trim().isEmpty || _saving ? null : _save,
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
            child: Text(text, style: context.text.small.copyWith(color: context.colors.accent)),
          ),
          if (action != null)
            GeoButton(label: action!, style: GeoButtonStyle.text, onPressed: onAction),
        ],
      ),
    );
  }
}

extension on TimeOfDay {
  String format24() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
