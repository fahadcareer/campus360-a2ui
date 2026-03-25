import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';

class A2UICatalog {
  // Store values of text inputs to be submitted by buttons
  static final Map<String, String> _fieldValues = {};

  // Callback to send messages - will be set by ChatProvider
  static void Function(String label, String action, {dynamic value})?
  onButtonClick;

  static Catalog get catalog => Catalog([
    CatalogItem(
      name: 'text',
      dataSchema: Schema.any(),
      widgetBuilder: (ic) {
        final data = ic.data as Map<String, dynamic>;
        final content = data['content'] ?? '';
        print(
          'DEBUG CATALOG: Building text widget with content: ${content.length > 20 ? content.substring(0, 20) : content}',
        );
        return Builder(
          builder: (context) {
            final bool isHeader =
                content.startsWith('---') || content.toUpperCase() == content;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: SelectableText(
                content,
                style: TextStyle(
                  fontSize: isHeader ? 16 : 14,
                  fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                  color: isHeader
                      ? (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF1E3A8A))
                      : (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : const Color(0xFF5F6368)),
                  height: 1.5,
                ),
              ),
            );
          },
        );
      },
    ),
    CatalogItem(
      name: 'button',
      dataSchema: Schema.any(),
      widgetBuilder: (ic) {
        final data = ic.data as Map<String, dynamic>;
        final action = data['action'] as String?;
        final label = data['label'] ?? '';

        return Builder(
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: ElevatedButton(
                onPressed: action != null && onButtonClick != null
                    ? () {
                        print('DEBUG: Button clicked with action: $action');
                        // Try to find a corresponding value if this is a submission button
                        Object? value;
                        if (action.startsWith('action_submit_')) {
                          final fieldKey =
                              'set_${action.replaceFirst('action_submit_', '')}';
                          value = _fieldValues[fieldKey];
                          print('DEBUG: Found value for $fieldKey: $value');
                        }
                        onButtonClick!(label, action, value: value);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  elevation: 2,
                  shadowColor: const Color(0xFF1E3A8A).withAlpha(102),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
    CatalogItem(
      name: 'column',
      dataSchema: Schema.any(),
      widgetBuilder: (ic) {
        final data = ic.data as Map<String, dynamic>;
        final children = data['children'] as List?;
        print(
          'DEBUG CATALOG: Building column widget with ${children?.length ?? 0} children',
        );

        return Builder(
          builder: (context) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (children != null)
                  ...children.map((childId) {
                    return ic.buildChild(childId.toString());
                  }),
              ],
            );
          },
        );
      },
    ),
    CatalogItem(
      name: 'text_input',
      dataSchema: Schema.any(),
      widgetBuilder: (ic) {
        final data = ic.data as Map<String, dynamic>;
        return Builder(
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: TextField(
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: data['label'],
                  labelStyle: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white12 : Colors.grey.shade300,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white12 : Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF1E3A8A),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (val) {
                  final action = data['action'] as String?;
                  if (action != null) {
                    _fieldValues[action] = val;
                  }
                },
                onSubmitted: (val) {
                  final action = data['action'] as String?;
                  if (action != null && onButtonClick != null) {
                    onButtonClick!(data['label'] ?? '', action, value: val);
                  }
                },
              ),
            );
          },
        );
      },
    ),
    CatalogItem(
      name: 'datepicker',
      dataSchema: Schema.any(),
      widgetBuilder: (ic) {
        final data = ic.data as Map<String, dynamic>;
        return Builder(
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade300,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 51 : 13),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null &&
                        data['action'] != null &&
                        onButtonClick != null) {
                      // Format: YYYY-MM-DD
                      final formatted =
                          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                      onButtonClick!(
                        'Selected: $formatted',
                        "${data['action']}_$formatted",
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    title: Text(
                      data['label'] ?? 'Select Date',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.calendar_today,
                      color: Color(0xFF1E3A8A),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
    CatalogItem(
      name: 'timepicker',
      dataSchema: Schema.any(),
      widgetBuilder: (ic) {
        final data = ic.data as Map<String, dynamic>;
        return Builder(
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade300,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 51 : 13),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null &&
                        data['action'] != null &&
                        onButtonClick != null) {
                      // Format: HH:MM
                      final formatted =
                          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                      onButtonClick!(
                        'Selected: $formatted',
                        "${data['action']}_$formatted",
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    title: Text(
                      data['label'] ?? 'Select Time',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.access_time,
                      color: Color(0xFF1E3A8A),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
    CatalogItem(
      name: 'confirmation_card',
      dataSchema: Schema.any(),
      widgetBuilder: (ic) {
        final data = ic.data as Map<String, dynamic>;
        return Builder(
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Card(
                elevation: 2,
                shadowColor: Colors.black.withAlpha(isDark ? 51 : 26),
                color: isDark ? const Color(0xFF334155) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        data['title'] ?? 'Confirm',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (data['fields'] != null)
                        ...(data['fields'] as List).map((f) {
                          final label = (f['label'] ?? '').toString();
                          final value = (f['value'] ?? '').toString();
                          final isHeader = value.isEmpty;

                          if (isHeader) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                top: 16,
                                bottom: 8,
                              ),
                              child: SelectableText(
                                label,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isDark
                                      ? const Color(0xFF60A5FA)
                                      : const Color(0xFF1E40AF),
                                ),
                              ),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: SelectableText(
                                    "$label:",
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Builder(
                                    builder: (context) {
                                      final isUrl = value.startsWith('http');
                                      if (isUrl) {
                                        return InkWell(
                                          onTap: () async {
                                            final uri = Uri.tryParse(value);
                                            if (uri != null) {
                                              await launchUrl(
                                                uri,
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                            }
                                          },
                                          child: Text(
                                            value,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                              color: Colors.blue,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor: Colors.blue,
                                            ),
                                          ),
                                        );
                                      }
                                      return SelectableText(
                                        value,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF2C3E50),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      if ((data['confirm_action'] != null &&
                              data['confirm_action'] != "") ||
                          (data['cancel_action'] != null &&
                              data['cancel_action'] != "") ||
                          (data['edit_action'] != null &&
                              data['edit_action'] != "") ||
                          (data['detail_action'] != null &&
                              data['detail_action'] != ""))
                        const SizedBox(height: 24),
                      if ((data['confirm_action'] != null &&
                              data['confirm_action'] != "") ||
                          (data['cancel_action'] != null &&
                              data['cancel_action'] != "") ||
                          (data['edit_action'] != null &&
                              data['edit_action'] != "") ||
                          (data['detail_action'] != null &&
                              data['detail_action'] != ""))
                        Column(
                          children: [
                            if (data['detail_action'] != null &&
                                data['detail_action'] != "")
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: onButtonClick != null
                                        ? () => onButtonClick!(
                                            data['detail_label'] ??
                                                'View Details',
                                            data['detail_action'],
                                          )
                                        : null,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      side: const BorderSide(
                                        color: Color(0xFF1E3A8A),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      data['detail_label'] ?? 'View Details',
                                      style: const TextStyle(
                                        color: Color(0xFF1E3A8A),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (data['edit_action'] != null &&
                                data['edit_action'] != "")
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: onButtonClick != null
                                        ? () => onButtonClick!(
                                            data['edit_label'] ?? 'Edit',
                                            data['edit_action'],
                                          )
                                        : null,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      side: const BorderSide(
                                        color: Color(0xFF1E3A8A),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      data['edit_label'] ?? 'Edit',
                                      style: const TextStyle(
                                        color: Color(0xFF1E3A8A),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Row(
                              children: [
                                if (data['cancel_action'] != null &&
                                    data['cancel_action'] != "")
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed:
                                          data['cancel_action'] != null &&
                                              onButtonClick != null
                                          ? () => onButtonClick!(
                                              data['cancel_label'] ?? 'Cancel',
                                              data['cancel_action'],
                                            )
                                          : null,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFF1E3A8A),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        data['cancel_label'] ?? 'Cancel',
                                        style: const TextStyle(
                                          color: Color(0xFF1E3A8A),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (data['cancel_action'] != null &&
                                    data['cancel_action'] != "" &&
                                    data['confirm_action'] != null &&
                                    data['confirm_action'] != "")
                                  const SizedBox(width: 12),
                                if (data['confirm_action'] != null &&
                                    data['confirm_action'] != "")
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed:
                                          data['confirm_action'] != null &&
                                              onButtonClick != null
                                          ? () => onButtonClick!(
                                              data['confirm_label'] ??
                                                  'Confirm',
                                              data['confirm_action'],
                                            )
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF1E3A8A,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        data['confirm_label'] ?? 'Confirm',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
    CatalogItem(
      name: 'text_input_with_button',
      dataSchema: Schema.any(),
      widgetBuilder: (ic) {
        final data = ic.data as Map<String, dynamic>;
        final String action = data['action'] ?? '';
        final String buttonAction = data['button_action'] ?? '';
        final String label = data['label'] ?? '';
        final String buttonLabel = data['button_label'] ?? 'Submit';

        return Builder(
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: label,
                      labelStyle: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : Colors.grey.shade300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF1E3A8A),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (val) {
                      _fieldValues[action] = val;
                    },
                    onSubmitted: (val) {
                      if (onButtonClick != null) {
                        onButtonClick!(buttonLabel, buttonAction, value: val);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: onButtonClick != null
                        ? () {
                            final val = _fieldValues[action];
                            onButtonClick!(
                              buttonLabel,
                              buttonAction,
                              value: val,
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      buttonLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ),
    CatalogItem(
      name: 'select',
      dataSchema: Schema.any(),
      widgetBuilder: (ic) {
        final data = ic.data as Map<String, dynamic>;
        final options =
            (data['options'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final action = data['action'] as String?;

        return Builder(
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Card(
                color: isDark ? const Color(0xFF334155) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data['label'] != null)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          data['label'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ...options.map((opt) {
                      final val = opt['value'].toString();
                      final label = opt['label'].toString();
                      return ListTile(
                        title: Text(
                          label,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        onTap: () {
                          if (action != null && onButtonClick != null) {
                            onButtonClick!(label, "${action}_$val");
                          }
                        },
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF1E3A8A),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            );
          },
        );
      },
    ),
    CatalogItem(
      name: 'meeting_form',
      dataSchema: Schema.any(),
      widgetBuilder: (ic) {
        final data = ic.data as Map<String, dynamic>;
        final userOptions =
            (data['user_options'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final submitAction = data['submit_action'] as String?;
        print('DEBUG: meeting_form data keys: ${data.keys.toList()}');
        print('DEBUG: initial_values raw: ${data['initial_values']}');

        final initialValues = (data['initial_values'] as Map?)
            ?.cast<String, dynamic>();

        return MeetingFormWidget(
          userOptions: userOptions,
          submitAction: submitAction,
          initialValues: initialValues,
        );
      },
    ),
    CatalogItem(
      name: 'user_selection',
      dataSchema: Schema.any(),
      widgetBuilder: (ic) {
        final data = ic.data as Map<String, dynamic>;
        final users =
            (data['users'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final title = data['title'] as String? ?? "Select User";
        final onSelectAction = data['onSelectAction'] as String?;

        return UserSelectionWidget(
          users: users,
          title: title,
          onSelectAction: onSelectAction,
        );
      },
    ),
    CatalogItem(
      name: 'task_form',
      dataSchema: Schema.any(),
      widgetBuilder: (ic) {
        final data = ic.data as Map<String, dynamic>;
        final userOptions =
            (data['user_options'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final submitAction = data['submit_action'] as String?;
        print('DEBUG: task_form data keys: ${data.keys.toList()}');
        print('DEBUG: initial_values raw: ${data['initial_values']}');

        final initialValues = (data['initial_values'] as Map?)
            ?.cast<String, dynamic>();

        return TaskFormWidget(
          userOptions: userOptions,
          submitAction: submitAction,
          initialValues: initialValues,
        );
      },
    ),
    CatalogItem(
      name: 'leave_form',
      dataSchema: Schema.any(),
      widgetBuilder: (ic) {
        final data = ic.data as Map<String, dynamic>;
        final leaveQuota =
            (data['leave_quota'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final submitAction = data['submit_action'] as String?;

        return LeaveRequestFormWidget(
          leaveQuota: leaveQuota,
          submitAction: submitAction,
        );
      },
    ),
    CatalogItem(
      name: 'meeting_grid',
      dataSchema: Schema.any(),
      widgetBuilder: (ic) {
        final data = ic.data as Map<String, dynamic>;
        final meetings =
            (data['meetings'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        print(
          'DEBUG CATALOG: Building meeting_grid with ${meetings.length} meetings',
        );
        return MeetingGrid(meetings: meetings);
      },
    ),
    CatalogItem(
      name: 'meeting_calendar',
      dataSchema: Schema.any(),
      widgetBuilder: (ic) {
        final data = ic.data as Map<String, dynamic>;
        final meetings =
            (data['meetings'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final initialDateStr = data['initial_date'] as String?;
        return MeetingCalendar(meetings: meetings, initialDate: initialDateStr);
      },
    ),
    CatalogItem(
      name: 'task_grid',
      dataSchema: Schema.any(),
      widgetBuilder: (ic) {
        final data = ic.data as Map<String, dynamic>;
        final tasks =
            (data['tasks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        return TaskGrid(tasks: tasks);
      },
    ),
    CatalogItem(
      name: 'task_calendar',
      dataSchema: Schema.any(),
      widgetBuilder: (ic) {
        final data = ic.data as Map<String, dynamic>;
        final tasks =
            (data['tasks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final initialDateStr = data['initial_date'] as String?;
        return TaskCalendar(tasks: tasks, initialDate: initialDateStr);
      },
    ),
    CatalogItem(
      name: 'unified_calendar',
      dataSchema: Schema.any(),
      widgetBuilder: (ic) {
        final data = ic.data as Map<String, dynamic>;
        final items =
            (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final initialDateStr = data['initial_date'] as String?;
        return UnifiedCalendar(items: items, initialDate: initialDateStr);
      },
    ),
    CatalogItem(
      name: 'multi_select',
      dataSchema: Schema.any(),
      widgetBuilder: (ic) {
        final data = ic.data as Map<String, dynamic>;
        final options =
            (data['options'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final action = data['action'] as String?;

        // Use a ValueNotifier to manage state cleanly without StatefulWidget overhead for now,
        // or ideally this should be a StatefulWidget, but CatalogItem expects a builder.
        // Since builder can't easily hold state, we rely on StatefulBuilder.
        final selectedValues = <String>{};

        return Builder(
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return StatefulBuilder(
              builder: (context, setState) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: Card(
                    color: isDark ? const Color(0xFF334155) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            data['label'] ?? 'Select Items',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        ...options.map((opt) {
                          final val = opt['value'].toString();
                          final label = opt['label'].toString();
                          final isSelected = selectedValues.contains(val);
                          return CheckboxListTile(
                            title: Text(
                              label,
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            value: isSelected,
                            onChanged: (bool? checked) {
                              setState(() {
                                if (checked == true) {
                                  selectedValues.add(val);
                                } else {
                                  selectedValues.remove(val);
                                }
                              });
                            },
                            activeColor: const Color(0xFF1E3A8A),
                          );
                        }),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  selectedValues.isNotEmpty &&
                                      action != null &&
                                      onButtonClick != null
                                  ? () {
                                      // Send comma separated values
                                      final csv = selectedValues.join(',');
                                      onButtonClick!(
                                        'Selected: ${selectedValues.length} items',
                                        "${action}_$csv",
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text("Confirm Selection"),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    ),
    CatalogItem(
      name: 'selection_card',
      dataSchema: Schema.any(),
      widgetBuilder: (ic) {
        final data = ic.data as Map<String, dynamic>;
        final options =
            (data['options'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final title = data['title'] ?? 'Select Option';

        return Builder(
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Card(
                elevation: 4,
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...options.map((opt) {
                        final label = opt['label'].toString();
                        final value = opt['value'].toString();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ElevatedButton(
                            onPressed: onButtonClick != null
                                ? () => onButtonClick!(
                                    label,
                                    "action_meeting_provider_$value",
                                  )
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? const Color(0xFF334155)
                                  : Colors.grey.shade100,
                              foregroundColor: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E3A8A),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.grey.shade300,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: Text(
                                    label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(right: 16),
                                  child: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
    CatalogItem(
      name: 'bar_chart',
      dataSchema: Schema.any(),
      widgetBuilder: (ic) {
        final data = ic.data as Map<String, dynamic>;
        return A2UICatalog._buildBarChart(data);
      },
    ),
    CatalogItem(
      name: 'pie_chart',
      dataSchema: Schema.any(),
      widgetBuilder: (ic) {
        final data = ic.data as Map<String, dynamic>;
        return A2UICatalog._buildPieChart(data);
      },
    ),
  ], catalogId: 'a2ui.org:standard_catalog_0_8_0');

  // --- Helper Methods for Forms ---

  static Widget _buildFieldLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }

  static Widget _buildTextField(
    TextEditingController controller,
    String hint,
    bool isDark, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
        filled: true,
        fillColor: isDark ? Colors.white.withAlpha(13) : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
      ),
    );
  }

  static Widget _buildPickerButton(
    BuildContext context,
    String text,
    IconData icon,
    bool isDark,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(13) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF1E3A8A)),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildMultiSelectDropdown(
    BuildContext context,
    String hint,
    List<Map<String, dynamic>> options,
    List<String> selected,
    bool isDark,
    Function(String) onToggle,
  ) {
    // Determine display text
    String displayText;
    if (selected.isEmpty) {
      displayText = hint;
    } else {
      final labels = selected.map((s) {
        return options.firstWhere(
              (o) => o['value'] == s,
              orElse: () => {'label': s},
            )['label']
            as String;
      }).toList();
      displayText = labels.join(", ");
    }

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (dialogContext) {
            String searchQuery = '';
            return StatefulBuilder(
              builder: (sbContext, sbState) {
                final filteredOptions = searchQuery.isEmpty
                    ? options
                    : options.where((o) {
                        final label = (o['label'] ?? '')
                            .toString()
                            .toLowerCase();
                        return label.contains(searchQuery.toLowerCase());
                      }).toList();
                return AlertDialog(
                  backgroundColor: isDark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  title: Text(
                    hint,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Search bar
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: TextField(
                            autofocus: false,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              hintStyle: TextStyle(
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: isDark ? Colors.white38 : Colors.black38,
                                size: 20,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white.withAlpha(20)
                                  : Colors.grey.shade100,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1E3A8A),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onChanged: (val) {
                              sbState(() => searchQuery = val);
                            },
                          ),
                        ),
                        // Results list
                        Flexible(
                          child: filteredOptions.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    'No results found',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black38,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: filteredOptions.length,
                                  itemBuilder: (ctx, index) {
                                    final opt = filteredOptions[index];
                                    final val = opt['value'].toString();
                                    final isSelected = selected.contains(val);
                                    return CheckboxListTile(
                                      title: Text(
                                        opt['label'],
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: 14,
                                        ),
                                      ),
                                      value: isSelected,
                                      onChanged: (bool? checked) {
                                        onToggle(val);
                                        sbState(() {});
                                      },
                                      activeColor: const Color(0xFF1E3A8A),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text(
                        "Done",
                        style: TextStyle(
                          color: Color(0xFF1E3A8A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                );
              },
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(13) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected.isEmpty
                      ? (isDark ? Colors.white24 : Colors.black26)
                      : (isDark ? Colors.white : Colors.black87),
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: isDark ? Colors.white30 : Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildSingleSelectDropdown(
    String hint,
    List<Map<String, dynamic>> options,
    String? selected,
    bool isDark,
    Function(String) onSelect,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(13) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          hint: Text(
            hint,
            style: TextStyle(
              color: isDark ? Colors.white24 : Colors.black26,
              fontSize: 14,
            ),
          ),
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          items: options.map((opt) {
            return DropdownMenuItem<String>(
              value: opt['value'].toString(),
              child: Text(
                opt['label'],
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) onSelect(val);
          },
        ),
      ),
    );
  }

  static Widget _buildBarChart(Map<String, dynamic> data) {
    final List<String> labels = List<String>.from(data['labels'] ?? []);
    final List<double> values = List<double>.from(
      (data['values'] as List? ?? []).map((e) => (e as num).toDouble()),
    );
    final String title = data['title'] ?? '';

    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          color: isDark ? const Color(0xFF334155) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: values.isEmpty
                          ? 10
                          : values.reduce((a, b) => a > b ? a : b) * 1.2,
                      barGroups: values.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value,
                              color: const Color(0xFF1E3A8A),
                              width: 16,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              int index = value.toInt();
                              if (index >= 0 && index < labels.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    labels[index],
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: isDark ? Colors.white10 : Colors.black12,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildPieChart(Map<String, dynamic> data) {
    final List<dynamic> items = data['data'] ?? [];
    final String title = data['title'] ?? '';

    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          color: isDark ? const Color(0xFF334155) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: items.asMap().entries.map((entry) {
                        final item = entry.value;
                        return PieChartSectionData(
                          value: (item['value'] as num).toDouble(),
                          title: '${item['value']}',
                          radius: 50,
                          color: _getColor(item['color'], entry.key),
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          badgeWidget: _buildPieBadge(item['label'], isDark),
                          badgePositionPercentageOffset: 1.3,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Legend
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: items.asMap().entries.map((entry) {
                    final item = entry.value;
                    final color = _getColor(item['color'], entry.key);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item['label'],
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildPieBadge(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.black54 : Colors.white70,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  static Color _getColor(String? colorStr, int index) {
    if (colorStr != null) {
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
      }
      switch (colorStr.toLowerCase()) {
        case 'blue':
          return const Color(0xFF1E3A8A);
        case 'red':
          return Colors.red;
        case 'green':
          return Colors.green;
        case 'orange':
          return Colors.orange;
        case 'purple':
          return Colors.purple;
      }
    }
    // Default palette
    final colors = [
      const Color(0xFF1E3A8A),
      const Color(0xFF3B82F6),
      const Color(0xFF60A5FA),
      const Color(0xFF93C5FD),
      const Color(0xFFBFDBFE),
    ];
    return colors[index % colors.length];
  }
}

class MeetingFormWidget extends StatefulWidget {
  final List<Map<String, dynamic>> userOptions;
  final String? submitAction;
  final Map<String, dynamic>? initialValues;

  const MeetingFormWidget({
    super.key,
    required this.userOptions,
    this.submitAction,
    this.initialValues,
  });

  @override
  State<MeetingFormWidget> createState() => _MeetingFormWidgetState();
}

class _MeetingFormWidgetState extends State<MeetingFormWidget> {
  late DateTime selectedDate;
  late TimeOfDay fromTime;
  late TimeOfDay toTime;
  final List<String> selectedAttendees = [];
  String? selectedNoteTaker;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController linkController = TextEditingController();
  final TextEditingController locController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    fromTime = TimeOfDay.now();
    toTime = TimeOfDay.now().replacing(hour: (TimeOfDay.now().hour + 1) % 24);

    if (widget.initialValues != null) {
      final init = widget.initialValues!;
      if (init['title'] != null) titleController.text = init['title'];
      if (init['description'] != null)
        descController.text = init['description'];

      if (init['date'] != null) {
        try {
          selectedDate = DateTime.parse(init['date']);
        } catch (e) {
          debugPrint("Error parsing date: $e");
        }
      }

      if (init['from'] != null) {
        try {
          final parts = (init['from'] as String).split(":");
          if (parts.length >= 2) {
            fromTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
        } catch (e) {
          debugPrint("Error parsing from time: $e");
        }
      }

      if (init['to'] != null) {
        try {
          final parts = (init['to'] as String).split(":");
          if (parts.length >= 2) {
            toTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
        } catch (e) {
          debugPrint("Error parsing to time: $e");
        }
      }

      if (init['attendees'] != null) {
        if (init['attendees'] is List) {
          selectedAttendees.addAll(
            (init['attendees'] as List).map((e) => e.toString()),
          );
        }
      }

      if (init['location'] is String) {
        locController.text = init['location'];
      }

      if (init['meetingLink'] is String) {
        linkController.text = init['meetingLink'];
      }

      if (init['noteTaker'] is String) {
        selectedNoteTaker = init['noteTaker'];
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    linkController.dispose();
    locController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Card(
        elevation: 4,
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Schedule New Meeting",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              A2UICatalog._buildFieldLabel("Title", isDark),
              A2UICatalog._buildTextField(
                titleController,
                "Meeting Title",
                isDark,
              ),

              const SizedBox(height: 12),

              // Description
              A2UICatalog._buildFieldLabel("Description", isDark),
              A2UICatalog._buildTextField(
                descController,
                "Meeting Description",
                isDark,
                maxLines: 2,
              ),

              const SizedBox(height: 12),

              // Date & Times
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        A2UICatalog._buildFieldLabel("Date", isDark),
                        A2UICatalog._buildPickerButton(
                          context,
                          "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}",
                          Icons.calendar_today,
                          isDark,
                          () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() => selectedDate = picked);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        A2UICatalog._buildFieldLabel("From", isDark),
                        A2UICatalog._buildPickerButton(
                          context,
                          fromTime.format(context),
                          Icons.access_time,
                          isDark,
                          () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: fromTime,
                            );
                            if (picked != null) {
                              setState(() => fromTime = picked);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        A2UICatalog._buildFieldLabel("To", isDark),
                        A2UICatalog._buildPickerButton(
                          context,
                          toTime.format(context),
                          Icons.access_time,
                          isDark,
                          () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: toTime,
                            );
                            if (picked != null) {
                              setState(() => toTime = picked);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Attendees (Multi-select Dropdown)
              A2UICatalog._buildFieldLabel("Attendees", isDark),
              A2UICatalog._buildMultiSelectDropdown(
                context,
                "Select Attendees",
                widget.userOptions,
                selectedAttendees,
                isDark,
                (val) => setState(() {
                  if (selectedAttendees.contains(val)) {
                    selectedAttendees.remove(val);
                  } else {
                    selectedAttendees.add(val);
                  }
                }),
              ),

              const SizedBox(height: 12),

              // Note Taker (Single-select Dropdown)
              A2UICatalog._buildFieldLabel("Note Taker", isDark),
              A2UICatalog._buildSingleSelectDropdown(
                "Select Note Taker",
                widget.userOptions,
                selectedNoteTaker,
                isDark,
                (val) => setState(() => selectedNoteTaker = val),
              ),

              const SizedBox(height: 12),

              // Link & Location
              // Only show if it's NOT a Teams or Outlook meeting
              if (widget.initialValues?['provider'] != 'teams' &&
                  widget.initialValues?['provider'] != 'outlook') ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          A2UICatalog._buildFieldLabel("Location", isDark),
                          A2UICatalog._buildTextField(
                            locController,
                            "Location",
                            isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          A2UICatalog._buildFieldLabel("Meeting Link", isDark),
                          A2UICatalog._buildTextField(
                            linkController,
                            "https://...",
                            isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              ElevatedButton(
                onPressed: () {
                  if (A2UICatalog.onButtonClick != null &&
                      widget.submitAction != null) {
                    final Map<String, dynamic> formData = {
                      "title": titleController.text,
                      "description": descController.text,
                      "date":
                          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                      "from":
                          "${fromTime.hour.toString().padLeft(2, '0')}:${fromTime.minute.toString().padLeft(2, '0')}",
                      "to":
                          "${toTime.hour.toString().padLeft(2, '0')}:${toTime.minute.toString().padLeft(2, '0')}",
                      "attendees": selectedAttendees.join(","),
                      "noteTaker": selectedNoteTaker,
                      "location": locController.text,
                      "meetingLink": linkController.text,
                      "isTeam": "false", // Use false for individual attendees
                    };
                    A2UICatalog.onButtonClick!(
                      "Create Meeting",
                      widget.submitAction!,
                      value: formData,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Create Meeting",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskFormWidget extends StatefulWidget {
  final List<Map<String, dynamic>> userOptions;
  final String? submitAction;
  final Map<String, dynamic>? initialValues;

  const TaskFormWidget({
    super.key,
    required this.userOptions,
    this.submitAction,
    this.initialValues,
  });

  @override
  State<TaskFormWidget> createState() => _TaskFormWidgetState();
}

class _TaskFormWidgetState extends State<TaskFormWidget> {
  late DateTime selectedDate; // Start Date
  late DateTime toDate; // End Date (New)
  late TimeOfDay fromTime;
  late TimeOfDay toTime;
  String? selectedAssignee;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    toDate = DateTime.now(); // Default to today
    fromTime = TimeOfDay.now();
    toTime = TimeOfDay.now().replacing(hour: (TimeOfDay.now().hour + 1) % 24);

    if (widget.initialValues != null) {
      final init = widget.initialValues!;
      if (init['title'] != null) titleController.text = init['title'];
      if (init['description'] != null)
        descController.text = init['description'];

      if (init['date'] != null) {
        try {
          selectedDate = DateTime.parse(init['date']);
        } catch (e) {
          debugPrint("Error parsing date: $e");
        }
      }

      if (init['toDate'] != null) {
        try {
          toDate = DateTime.parse(init['toDate']);
        } catch (e) {
          debugPrint("Error parsing toDate: $e");
        }
      }

      if (init['from'] != null) {
        try {
          final parts = (init['from'] as String).split(":");
          if (parts.length >= 2) {
            fromTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
        } catch (e) {
          debugPrint("Error parsing from time: $e");
        }
      }

      if (init['to'] != null) {
        try {
          final parts = (init['to'] as String).split(":");
          if (parts.length >= 2) {
            toTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
        } catch (e) {
          debugPrint("Error parsing to time: $e");
        }
      }

      if (init['assignee'] != null) {
        selectedAssignee = init['assignee'].toString();
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Card(
        elevation: 4,
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Create New Task",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              A2UICatalog._buildFieldLabel("Title", isDark),
              A2UICatalog._buildTextField(
                titleController,
                "Task Title",
                isDark,
              ),

              const SizedBox(height: 12),

              // Description
              A2UICatalog._buildFieldLabel("Description", isDark),
              A2UICatalog._buildTextField(
                descController,
                "Task Description",
                isDark,
                maxLines: 2,
              ),

              const SizedBox(height: 12),

              // Start Date
              A2UICatalog._buildFieldLabel("Start Date", isDark),
              A2UICatalog._buildPickerButton(
                context,
                "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}",
                Icons.calendar_today,
                isDark,
                () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = picked;
                      if (toDate.isBefore(selectedDate)) {
                        toDate = selectedDate;
                      }
                    });
                  }
                },
              ),

              const SizedBox(height: 12),

              // End Date
              A2UICatalog._buildFieldLabel("End Date", isDark),
              A2UICatalog._buildPickerButton(
                context,
                "${toDate.year}-${toDate.month}-${toDate.day}",
                Icons.calendar_today,
                isDark,
                () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: toDate,
                    firstDate: selectedDate,
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => toDate = picked);
                  }
                },
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        A2UICatalog._buildFieldLabel("From", isDark),
                        A2UICatalog._buildPickerButton(
                          context,
                          fromTime.format(context),
                          Icons.access_time,
                          isDark,
                          () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: fromTime,
                            );
                            if (picked != null) {
                              setState(() => fromTime = picked);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        A2UICatalog._buildFieldLabel("To", isDark),
                        A2UICatalog._buildPickerButton(
                          context,
                          toTime.format(context),
                          Icons.access_time,
                          isDark,
                          () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: toTime,
                            );
                            if (picked != null) {
                              setState(() => toTime = picked);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Assignee (Single-select Dropdown)
              A2UICatalog._buildFieldLabel("Assignee", isDark),
              A2UICatalog._buildSingleSelectDropdown(
                "Select Assignee",
                widget.userOptions,
                selectedAssignee,
                isDark,
                (val) => setState(() => selectedAssignee = val),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  if (A2UICatalog.onButtonClick != null &&
                      widget.submitAction != null) {
                    final Map<String, dynamic> formData = {
                      "title": titleController.text,
                      "description": descController.text,
                      "date":
                          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                      "toDate":
                          "${toDate.year}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}",
                      "from":
                          "${fromTime.hour.toString().padLeft(2, '0')}:${fromTime.minute.toString().padLeft(2, '0')}",
                      "to":
                          "${toTime.hour.toString().padLeft(2, '0')}:${toTime.minute.toString().padLeft(2, '0')}",
                      "assignee": selectedAssignee,
                    };
                    A2UICatalog.onButtonClick!(
                      "Create Task",
                      widget.submitAction!,
                      value: formData,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Create Task",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LeaveRequestFormWidget extends StatefulWidget {
  final List<Map<String, dynamic>> leaveQuota;
  final String? submitAction;

  const LeaveRequestFormWidget({
    super.key,
    required this.leaveQuota,
    this.submitAction,
  });

  @override
  State<LeaveRequestFormWidget> createState() => _LeaveRequestFormWidgetState();
}

class _LeaveRequestFormWidgetState extends State<LeaveRequestFormWidget> {
  late DateTime fromDate;
  late DateTime toDate;
  late TimeOfDay startTime;
  late TimeOfDay endTime;
  String? selectedLeaveTypeId;
  bool isFullDay = true;

  final TextEditingController reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fromDate = DateTime.now();
    toDate = DateTime.now();
    startTime = const TimeOfDay(hour: 9, minute: 0);
    endTime = const TimeOfDay(hour: 17, minute: 0);
    if (widget.leaveQuota.isNotEmpty) {
      selectedLeaveTypeId = widget.leaveQuota.first['leaveTypeId']?.toString();
    }
  }

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Card(
        elevation: 4,
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Apply for Leave",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 20),

              // Leave Type
              A2UICatalog._buildFieldLabel("Leave Type", isDark),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withAlpha(13)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedLeaveTypeId,
                    isExpanded: true,
                    dropdownColor: isDark
                        ? const Color(0xFF1E293B)
                        : Colors.white,
                    hint: Text(
                      "Select Leave Type",
                      style: TextStyle(
                        color: isDark ? Colors.white24 : Colors.black26,
                        fontSize: 14,
                      ),
                    ),
                    items: widget.leaveQuota.map((q) {
                      final name = q['leaveTypeName'] ?? "Unknown";
                      final count = q['leaveCount'] ?? 0;
                      return DropdownMenuItem<String>(
                        value: q['leaveTypeId']?.toString(),
                        child: Text(
                          "$name ($count left)",
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => selectedLeaveTypeId = val),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Dates
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        A2UICatalog._buildFieldLabel("From", isDark),
                        A2UICatalog._buildPickerButton(
                          context,
                          "${fromDate.year}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}",
                          Icons.calendar_today,
                          isDark,
                          () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: fromDate,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 30),
                              ),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() {
                                fromDate = picked;
                                if (toDate.isBefore(picked)) toDate = picked;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        A2UICatalog._buildFieldLabel("To", isDark),
                        A2UICatalog._buildPickerButton(
                          context,
                          "${toDate.year}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}",
                          Icons.calendar_today,
                          isDark,
                          () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: toDate,
                              firstDate: fromDate,
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() => toDate = picked);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Full Day Toggle
              Row(
                children: [
                  Text(
                    "Full Day",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: isFullDay,
                    onChanged: (val) => setState(() => isFullDay = val),
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF1E3A8A),
                    inactiveThumbColor: isDark
                        ? Colors.grey.shade400
                        : Colors.grey.shade100,
                    inactiveTrackColor: isDark
                        ? Colors.white24
                        : Colors.grey.shade300,
                  ),
                ],
              ),

              if (!isFullDay) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          A2UICatalog._buildFieldLabel("Start Time", isDark),
                          A2UICatalog._buildPickerButton(
                            context,
                            startTime.format(context),
                            Icons.access_time,
                            isDark,
                            () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: startTime,
                              );
                              if (picked != null) {
                                setState(() => startTime = picked);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          A2UICatalog._buildFieldLabel("End Time", isDark),
                          A2UICatalog._buildPickerButton(
                            context,
                            endTime.format(context),
                            Icons.access_time,
                            isDark,
                            () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: endTime,
                              );
                              if (picked != null) {
                                setState(() => endTime = picked);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Reason
              A2UICatalog._buildFieldLabel("Reason", isDark),
              A2UICatalog._buildTextField(
                reasonController,
                "Reason for leave",
                isDark,
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  if (A2UICatalog.onButtonClick != null &&
                      widget.submitAction != null) {
                    final selectedTypeData = widget.leaveQuota.firstWhere(
                      (q) =>
                          q['leaveTypeId']?.toString() == selectedLeaveTypeId,
                      orElse: () => {},
                    );

                    final Map<String, dynamic> formData = {
                      "from":
                          "${fromDate.year}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}",
                      "to":
                          "${toDate.year}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}",
                      "reason": reasonController.text,
                      "leaveTypeId": selectedLeaveTypeId,
                      "type":
                          selectedTypeData['leaveTypeName'], // Required for API display
                      "fullDay": isFullDay,
                      "startTime": isFullDay
                          ? null
                          : "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}",
                      "endTime": isFullDay
                          ? null
                          : "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}",
                    };
                    A2UICatalog.onButtonClick!(
                      "Submit Leave Request",
                      widget.submitAction!,
                      value: formData,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Submit Request",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserSelectionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final String title;
  final String? onSelectAction;

  const UserSelectionWidget({
    super.key,
    required this.users,
    this.title = "Select User",
    this.onSelectAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      constraints: const BoxConstraints(maxHeight: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: users.length,
              separatorBuilder: (context, index) => Divider(
                color: isDark ? Colors.white12 : Colors.black12,
                height: 1,
              ),
              itemBuilder: (context, index) {
                final user = users[index];
                final name = user['name'] ?? "Unknown";
                final image = user['image'];
                final empId = user['empID'] ?? "";

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
                    backgroundImage:
                        (image != null && image.toString().startsWith('http'))
                        ? NetworkImage(image.toString())
                        : null,
                    child:
                        (image == null || !image.toString().startsWith('http'))
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : "?",
                            style: const TextStyle(color: Color(0xFF1E3A8A)),
                          )
                        : null,
                  ),
                  title: Text(
                    name,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: empId.isNotEmpty
                      ? Text(
                          "ID: $empId",
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 12,
                          ),
                        )
                      : null,
                  trailing: Icon(
                    Icons.chevron_right,
                    color: isDark ? Colors.white38 : Colors.black38,
                    size: 20,
                  ),
                  onTap: () {
                    if (A2UICatalog.onButtonClick != null &&
                        onSelectAction != null) {
                      A2UICatalog.onButtonClick!(
                        "Select $name",
                        onSelectAction!,
                        value: user,
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MeetingGrid extends StatelessWidget {
  final List<Map<String, dynamic>> meetings;

  const MeetingGrid({super.key, required this.meetings});

  @override
  Widget build(BuildContext context) {
    // Group meetings by provider
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final m in meetings) {
      final provider = m['provider'] ?? 'mandoobee';
      grouped.putIfAbsent(provider, () => []).add(m);
    }

    final providers = ['mandoobee', 'teams', 'outlook'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final itemWidth = availableWidth > 200
            ? (availableWidth - 32) / 2
            : availableWidth - 16;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: providers.map((p) {
            final groupMeetings = grouped[p] ?? [];
            if (groupMeetings.isEmpty) return const SizedBox.shrink();

            String label = 'MANDOOBEE MEETINGS';
            if (p == 'teams') label = 'TEAMS MEETINGS';
            if (p == 'outlook') label = 'OUTLOOK MEETINGS';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : const Color(0xFF1E3A8A),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: groupMeetings.map((m) {
                      return SizedBox(
                        width: itemWidth,
                        child: MeetingCompactCard(data: m),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}

class MeetingCalendar extends StatefulWidget {
  final List<Map<String, dynamic>> meetings;
  final String? initialDate;

  const MeetingCalendar({super.key, required this.meetings, this.initialDate});

  @override
  State<MeetingCalendar> createState() => _MeetingCalendarState();
}

class _MeetingCalendarState extends State<MeetingCalendar> {
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    if (widget.initialDate != null) {
      try {
        selectedDate = DateTime.parse(widget.initialDate!);
      } catch (e) {
        debugPrint("Error parsing initial calendar date: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Group meetings by day for the calendar logic if needed,
    // but here we just filter for the timeline view
    final dayMeetings = widget.meetings.where((m) {
      try {
        // This is a bit fragile due to string parsing, but matches our backend _format_dates
        // Jan 01, 10:00 AM -> Jan 01
        // We compare formatted month/day
        final mDate = m['time_range'] as String;
        final selectedDateFmt =
            "${_getMonthAbbr(selectedDate.month)} ${selectedDate.day.toString().padLeft(2, '0')}";
        return mDate.startsWith(selectedDateFmt);
      } catch (e) {
        return false;
      }
    }).toList();

    return Column(
      children: [
        _buildWeekStrip(isDark),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Text(
            "${_getMonthName(selectedDate.month)} ${selectedDate.day}, ${selectedDate.year}",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E3A8A),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (dayMeetings.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  "No meetings for this day",
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: dayMeetings
                  .map((m) => _buildTimelineItem(m, isDark))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildWeekStrip(bool isDark) {
    // Show 14 days starting from Monday of the selectedDate's week
    final startOfWeek = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );

    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 14, // Show 2 weeks
        itemBuilder: (context, index) {
          final day = startOfWeek.add(Duration(days: index));
          final isSelected =
              day.day == selectedDate.day &&
              day.month == selectedDate.month &&
              day.year == selectedDate.year;

          return GestureDetector(
            onTap: () => setState(() => selectedDate = day),
            child: Container(
              width: 55,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1E3A8A)
                    : (isDark ? const Color(0xFF334155) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1E3A8A)
                      : (isDark ? Colors.white10 : Colors.grey.shade200),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF1E3A8A).withAlpha(76),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getWeekdayAbbr(day.weekday),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white70
                          : (isDark ? Colors.white54 : Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day.day.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> meeting, bool isDark) {
    final timeStr = meeting['time_range']
        .split(',')[1]
        .trim(); // e.g., "10:00 AM - 11:00 AM"

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              timeStr.split('-')[0].trim(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              Container(
                width: 2,
                height: 60,
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (meeting['detail_action'] != null &&
                    A2UICatalog.onButtonClick != null) {
                  A2UICatalog.onButtonClick!(
                    meeting['title'],
                    meeting['detail_action'],
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meeting['title'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getWeekdayAbbr(int day) {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days[day - 1];
  }

  String _getMonthAbbr(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }

  String _getMonthName(int month) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return months[month - 1];
  }
}

class MeetingCompactCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const MeetingCompactCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = data['title'] ?? 'Meeting';
    final detailAction = data['detail_action'];
    final editAction = data['edit_action'];
    final cancelAction = data['cancel_action'];

    final provider = data['provider'] ?? 'mandoobee';
    final Color providerColor;
    if (provider == 'teams') {
      providerColor = const Color(0xFF4B53BC); // Teams purple/blue
    } else if (provider == 'outlook') {
      providerColor = const Color(0xFF0078D4); // Outlook blue
    } else {
      providerColor = const Color(0xFF1E3A8A); // Mandoobee default
    }

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withAlpha(isDark ? 51 : 26),
      color: isDark ? const Color(0xFF334155) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: provider != 'mandoobee'
            ? BorderSide(color: providerColor.withAlpha(100), width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (provider != 'mandoobee')
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: providerColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      provider == 'teams' ? Icons.videocam : Icons.mail,
                      size: 14,
                      color: providerColor,
                    ),
                  ),
              ],
            ),
            if (data['time_range'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  data['time_range'],
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (detailAction != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: A2UICatalog.onButtonClick != null
                      ? () => A2UICatalog.onButtonClick!(
                          data['detail_label'] ?? 'View Details',
                          detailAction,
                        )
                      : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: providerColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    data['detail_label'] ?? 'View Details',
                    style: TextStyle(
                      fontSize: 12,
                      color: providerColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (cancelAction != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: A2UICatalog.onButtonClick != null
                          ? () => A2UICatalog.onButtonClick!(
                              data['cancel_label'] ?? 'Cancel',
                              cancelAction,
                            )
                          : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: BorderSide(color: providerColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        data['cancel_label'] ?? 'Cancel',
                        style: TextStyle(
                          fontSize: 12,
                          color: providerColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (cancelAction != null && editAction != null)
                  const SizedBox(width: 8),
                if (editAction != null)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: A2UICatalog.onButtonClick != null
                          ? () => A2UICatalog.onButtonClick!(
                              data['edit_label'] ?? 'Edit',
                              editAction,
                            )
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: providerColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        data['edit_label'] ?? 'Edit',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

class TaskGrid extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;

  const TaskGrid({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        // Subtract horizontal padding (8*2) and spacing between items (12)
        // Ensure we don't divide by zero or negative
        final itemWidth = availableWidth > 200
            ? (availableWidth - 32) / 2
            : availableWidth - 16;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: tasks.map((t) {
              return SizedBox(
                width: itemWidth,
                child: TaskCompactCard(data: t),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class TaskCompactCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const TaskCompactCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = data['title'] ?? 'Task';
    final status = data['status'] ?? 'Pending';
    final detailAction = data['detail_action'];
    final editAction = data['edit_action'];

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'Completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'In Progress':
        statusColor = Colors.orange;
        statusIcon = Icons.autorenew;
        break;
      default:
        statusColor = Colors.blueGrey;
        statusIcon = Icons.hourglass_empty;
    }

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withAlpha(isDark ? 51 : 26),
      color: isDark ? const Color(0xFF334155) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (data['time_range'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  data['time_range'],
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (detailAction != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: A2UICatalog.onButtonClick != null
                      ? () => A2UICatalog.onButtonClick!(
                          data['detail_label'] ?? 'View Details',
                          detailAction,
                        )
                      : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: Color(0xFF1E3A8A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    data['detail_label'] ?? 'View Details',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (detailAction != null && editAction != null)
              const SizedBox(height: 8),
            if (editAction != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: A2UICatalog.onButtonClick != null
                      ? () => A2UICatalog.onButtonClick!(
                          data['edit_label'] ?? 'Edit',
                          editAction,
                        )
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    data['edit_label'] ?? 'Edit',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
class TaskCalendar extends StatefulWidget {
  final List<Map<String, dynamic>> tasks;
  final String? initialDate;

  const TaskCalendar({super.key, required this.tasks, this.initialDate});

  @override
  State<TaskCalendar> createState() => _TaskCalendarState();
}

class _TaskCalendarState extends State<TaskCalendar> {
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    if (widget.initialDate != null) {
      try {
        selectedDate = DateTime.parse(widget.initialDate!);
      } catch (e) {
        debugPrint("Error parsing initial calendar date for tasks: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dayTasks = widget.tasks.where((t) {
      try {
        final tDate = t['time_range'] as String;
        final selectedDateFmt =
            "${_getMonthAbbr(selectedDate.month)} ${selectedDate.day.toString().padLeft(2, '0')}";
        return tDate.startsWith(selectedDateFmt);
      } catch (e) {
        return false;
      }
    }).toList();

    return Column(
      children: [
        _buildWeekStrip(isDark),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Text(
            "${_getMonthName(selectedDate.month)} ${selectedDate.day}, ${selectedDate.year}",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E3A8A),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (dayTasks.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                Icon(Icons.assignment_turned_in,
                    size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  "No tasks for this day",
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: dayTasks
                  .map((t) => _buildTimelineItem(t, isDark))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildWeekStrip(bool isDark) {
    final startOfWeek = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );

    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 14,
        itemBuilder: (context, index) {
          final day = startOfWeek.add(Duration(days: index));
          final isSelected = day.day == selectedDate.day &&
              day.month == selectedDate.month &&
              day.year == selectedDate.year;

          return GestureDetector(
            onTap: () => setState(() => selectedDate = day),
            child: Container(
              width: 55,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1E3A8A)
                    : (isDark ? const Color(0xFF334155) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1E3A8A)
                      : (isDark ? Colors.white10 : Colors.grey.shade200),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF1E3A8A).withAlpha(76),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getWeekdayAbbr(day.weekday),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white70
                          : (isDark ? Colors.white54 : Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day.day.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> task, bool isDark) {
    final timeStr =
        task['time_range'].split(',')[1].trim(); // "10:00 AM - 11:00 AM"

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              timeStr.split('-')[0].trim(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              Container(
                width: 2,
                height: 70,
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (task['detail_action'] != null &&
                    A2UICatalog.onButtonClick != null) {
                  A2UICatalog.onButtonClick!(
                    task['title'],
                    task['detail_action'],
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task['title'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        if (task['status'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              task['status'].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    if (task['edit_action'] != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            if (A2UICatalog.onButtonClick != null) {
                              A2UICatalog.onButtonClick!(
                                task['edit_label'] ?? 'Edit',
                                task['edit_action'],
                              );
                            }
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 20),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            task['edit_label'] ?? 'Edit',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getWeekdayAbbr(int day) {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days[day - 1];
  }

  String _getMonthAbbr(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return months[month - 1];
  }

  String _getMonthName(int month) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return months[month - 1];
  }
}

class UnifiedCalendar extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String? initialDate;

  const UnifiedCalendar({super.key, required this.items, this.initialDate});

  @override
  State<UnifiedCalendar> createState() => _UnifiedCalendarState();
}

class _UnifiedCalendarState extends State<UnifiedCalendar> {
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    if (widget.initialDate != null) {
      try {
        selectedDate = DateTime.parse(widget.initialDate!);
      } catch (e) {
        debugPrint("Error parsing initial calendar date for unified view: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dayItems = widget.items.where((item) {
      try {
        final itemDate = item['time_range'] as String;
        final selectedDateFmt =
            "${_getMonthAbbr(selectedDate.month)} ${selectedDate.day.toString().padLeft(2, '0')}";
        return itemDate.startsWith(selectedDateFmt);
      } catch (e) {
        return false;
      }
    }).toList();

    return Column(
      children: [
        _buildWeekStrip(isDark),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Text(
            "${_getMonthName(selectedDate.month)} ${selectedDate.day}, ${selectedDate.year}",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E3A8A),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (dayItems.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                Icon(Icons.event_available,
                    size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  "Relax! Nothing scheduled for this day",
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: dayItems
                  .map((item) => _buildTimelineItem(item, isDark))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildWeekStrip(bool isDark) {
    final startOfWeek = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );

    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 14,
        itemBuilder: (context, index) {
          final day = startOfWeek.add(Duration(days: index));
          final isSelected = day.day == selectedDate.day &&
              day.month == selectedDate.month &&
              day.year == selectedDate.year;

          return GestureDetector(
            onTap: () => setState(() => selectedDate = day),
            child: Container(
              width: 55,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1E3A8A)
                    : (isDark ? const Color(0xFF334155) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1E3A8A)
                      : (isDark ? Colors.white10 : Colors.grey.shade200),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF1E3A8A).withAlpha(76),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getWeekdayAbbr(day.weekday),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white70
                          : (isDark ? Colors.white54 : Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day.day.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> item, bool isDark) {
    final timeRange = item['time_range'] as String? ?? "";
    final parts = timeRange.split(',');
    final timeStr = parts.length > 1 ? parts[1].trim() : timeRange;

    final type = item['type'] ?? 'meeting';
    final isMeeting = type == 'meeting';
    final provider = item['provider'] ?? 'mandoobee';

    Color providerColor;
    if (provider == 'teams') {
      providerColor = const Color(0xFF4B53BC);
    } else if (provider == 'outlook') {
      providerColor = const Color(0xFF0078D4);
    } else {
      providerColor = const Color(0xFF1E3A8A);
    }

    if (!isMeeting) {
      providerColor = const Color(0xFF0D9488); // Teal for tasks
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              timeStr.split('-')[0].trim(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: providerColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              Container(
                width: 2,
                height: 70,
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                final action = item['detail_action'];
                if (action != null && A2UICatalog.onButtonClick != null) {
                  A2UICatalog.onButtonClick!(
                    item['title'],
                    action,
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? providerColor.withOpacity(0.3)
                        : providerColor.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isMeeting ? Icons.videocam_outlined : Icons.assignment_outlined,
                          size: 14,
                          color: providerColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item['title'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        if (item['status'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: providerColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item['status'].toString().toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: providerColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    if (isMeeting && item['location'] != null && item['location'] != "")
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 10, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item['location'],
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (item['edit_action'] != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            if (A2UICatalog.onButtonClick != null) {
                              A2UICatalog.onButtonClick!(
                                item['edit_label'] ?? 'Edit',
                                item['edit_action'],
                              );
                            }
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 20),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            item['edit_label'] ?? 'Edit',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: providerColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getWeekdayAbbr(int day) {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days[day - 1];
  }

  String _getMonthAbbr(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return months[month - 1];
  }

  String _getMonthName(int month) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return months[month - 1];
  }
}
