import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../res/style/app_typography.dart';

class CustomTextForm extends StatefulWidget {
  final int maxLines;
  final int? maxLength;
  final String? label;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? lablelText;
  final bool enabled;
  final bool iseditable;
  final bool isMandatory;
  final String? initialValue;
  final String? prefixText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final String? Function(dynamic val)? validator; // Nullable validator
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapital;
  final bool obscureText;
  final bool enableInteractiveSelection;
  final void Function()? onTap;
  final Widget? prefixIcon;
  const CustomTextForm({
    Key? key,
    this.maxLines = 1,
    this.maxLength,
    this.label,
    required this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.iseditable = false,
    this.isMandatory = false,
    this.suffix,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.validator,
    this.lablelText,
    this.prefixText,
    this.initialValue,
    this.inputFormatters,
    this.textCapital = TextCapitalization.sentences,
    this.obscureText = false,
    this.enableInteractiveSelection = true,
    this.onTap,
    this.prefixIcon,
  }) : super(key: key);
  @override
  _CustomTextFormWidgetState createState() => _CustomTextFormWidgetState();
}

class _CustomTextFormWidgetState extends State<CustomTextForm> {
  //  late final TextEditingController controller;
  @override
  void initState() {
    super.initState();
    // controller = TextEditingController(text: widget.text);
  }

  @override
  void dispose() {
    //  controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextFormField(
    onTap: widget.onTap,
    // autofocus: true, // Removed autofocus to prevent keyboard popping up everywhere
    autocorrect: true,
    obscureText: widget.obscureText,
    initialValue: widget.initialValue,
    textCapitalization: widget.textCapital,
    scrollPadding: EdgeInsets.zero,
    readOnly: widget.iseditable,
    enableInteractiveSelection: widget.enableInteractiveSelection,
    style: TextStyles.b2!.copyWith(fontWeight: FontWeight.w400),
    keyboardType: widget.keyboardType,
    enabled: widget.enabled,
    validator: widget.validator,
    controller: widget.controller,
    onChanged: (content) => widget.onChanged(content),
    onFieldSubmitted: (content) => widget.onSubmitted?.call(content),
    decoration: InputDecoration(
      labelText: widget.lablelText,
      prefixText: widget.prefixText == null ? null : '${widget.prefixText}:  ',
      prefixIcon: widget.prefixIcon,
      border: OutlineInputBorder(
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.onSecondary,
        ),
        borderRadius: BorderRadius.circular(10.0),
      ),
      suffixIcon: widget.suffix,
      hintText: widget.label,
      filled: true,
      hintStyle: TextStyles.l1!.copyWith(color: Theme.of(context).hintColor),
      fillColor: Theme.of(context).colorScheme.surface,
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.onSecondary,
        ),
        borderRadius: BorderRadius.circular(10.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.onSecondary,
        ),
        borderRadius: BorderRadius.circular(10.0),
      ),
    ),
    maxLines: widget.maxLines,
    maxLength: widget.maxLength,
    inputFormatters: widget.inputFormatters,

    //  toolbarOptions: ToolbarOptions(),
  );
}
