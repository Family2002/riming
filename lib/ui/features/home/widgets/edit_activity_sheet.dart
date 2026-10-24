import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../domain/models/activity.dart';
import 'duration_label.dart';

class ActivityEditResult {
  const ActivityEditResult({
    required this.title,
    required this.startAt,
    this.endAt,
    this.clearEndAt = false,
  });

  final String title;
  final DateTime startAt;
  final DateTime? endAt;
  final bool clearEndAt;
}

Future<ActivityEditResult?> showEditActivitySheet(
  BuildContext context, {
  required Activity activity,
}) {
  return showModalBottomSheet<ActivityEditResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => _EditActivitySheet(activity: activity),
  );
}

class _EditActivitySheet extends StatefulWidget {
  const _EditActivitySheet({required this.activity});

  final Activity activity;

  @override
  State<_EditActivitySheet> createState() => _EditActivitySheetState();
}

class _EditActivitySheetState extends State<_EditActivitySheet> {
  late final TextEditingController _titleController;
  late DateTime _startAt;
  DateTime? _endAt;
  late bool _ongoing;

  @override
  void initState() {
    super.initState();
    final a = widget.activity;
    _titleController = TextEditingController(text: a.title);
    _startAt = a.startAt;
    _endAt = a.endAt;
    _ongoing = a.isOngoing;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startAt),
      helpText: '选择开始时间',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (time == null) return;
    setState(() {
      _startAt = DateTime(
        _startAt.year,
        _startAt.month,
        _startAt.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickEnd() async {
    final base = _endAt ?? DateTime.now();
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
      helpText: '选择结束时间',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (time == null) return;
    setState(() {
      _ongoing = false;
      _endAt = DateTime(
        _startAt.year,
        _startAt.month,
        _startAt.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写事项名称')),
      );
      return;
    }
    if (!_ongoing && _endAt != null && _endAt!.isBefore(_startAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('结束时间不能早于开始时间')),
      );
      return;
    }

    Navigator.of(context).pop(
      ActivityEditResult(
        title: title,
        startAt: _startAt,
        endAt: _ongoing ? null : _endAt,
        clearEndAt: _ongoing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('编辑事项', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '改错字或调整时间都可以',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: '事项名称',
                hintText: '例如：起床、通勤、开会…',
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(CupertinoIcons.play_fill, color: scheme.primary),
              title: const Text('开始时间'),
              subtitle: Text(formatClock(_startAt)),
              trailing: const Icon(CupertinoIcons.pencil),
              onTap: _pickStart,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('仍在进行中'),
              subtitle: Text(
                _ongoing ? '没有结束时间' : '已结束，可修改结束时间',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              value: _ongoing,
              onChanged: (v) {
                setState(() {
                  _ongoing = v;
                  if (!v && _endAt == null) {
                    _endAt = DateTime.now();
                  }
                });
              },
            ),
            if (!_ongoing)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(CupertinoIcons.stop_fill, color: scheme.primary),
                title: const Text('结束时间'),
                subtitle: Text(
                  _endAt == null ? '点击设置' : formatClock(_endAt!),
                ),
                trailing: const Icon(CupertinoIcons.pencil),
                onTap: _pickEnd,
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('保存'),
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
