import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_dimensions.dart';

/// Custom button widget with loading state and different variants
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool disabled;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.disabled = false,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
  });

  /// Emergency button variant (large, red, prominent)
  const CustomButton.emergency({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.disabled = false,
    this.icon,
  })  : variant = ButtonVariant.emergency,
        size = ButtonSize.large,
        backgroundColor = null,
        textColor = null,
        width = null;

  /// Secondary button variant
  const CustomButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.disabled = false,
    this.size = ButtonSize.medium,
    this.icon,
    this.width,
  })  : variant = ButtonVariant.secondary,
        backgroundColor = null,
        textColor = null;

  /// Text button variant
  const CustomButton.text({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.disabled = false,
    this.size = ButtonSize.medium,
    this.icon,
  })  : variant = ButtonVariant.text,
        backgroundColor = null,
        textColor = null,
        width = null;

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled || isLoading;
    
    switch (variant) {
      case ButtonVariant.primary:
        return _buildElevatedButton(context, isDisabled);
      case ButtonVariant.secondary:
        return _buildOutlinedButton(context, isDisabled);
      case ButtonVariant.text:
        return _buildTextButton(context, isDisabled);
      case ButtonVariant.emergency:
        return _buildEmergencyButton(context, isDisabled);
    }
  }

  Widget _buildElevatedButton(BuildContext context, bool isDisabled) {
    return SizedBox(
      width: width,
      height: _getButtonHeight(),
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.emergencyRed,
          foregroundColor: textColor ?? AppColors.textOnDark,
          disabledBackgroundColor: AppColors.mediumGray,
          disabledForegroundColor: AppColors.textLight,
          textStyle: _getTextStyle(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
        ),
        child: _buildButtonContent(),
      ),
    );
  }

  Widget _buildOutlinedButton(BuildContext context, bool isDisabled) {
    return SizedBox(
      width: width,
      height: _getButtonHeight(),
      child: OutlinedButton(
        onPressed: isDisabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: backgroundColor ?? AppColors.emergencyRed,
          disabledForegroundColor: AppColors.textLight,
          side: BorderSide(
            color: isDisabled 
                ? AppColors.mediumGray 
                : (backgroundColor ?? AppColors.emergencyRed),
            width: 2,
          ),
          textStyle: _getTextStyle(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
        ),
        child: _buildButtonContent(),
      ),
    );
  }

  Widget _buildTextButton(BuildContext context, bool isDisabled) {
    return SizedBox(
      height: _getButtonHeight(),
      child: TextButton(
        onPressed: isDisabled ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: backgroundColor ?? AppColors.emergencyRed,
          disabledForegroundColor: AppColors.textLight,
          textStyle: _getTextStyle(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
        ),
        child: _buildButtonContent(),
      ),
    );
  }

  Widget _buildEmergencyButton(BuildContext context, bool isDisabled) {
    return Container(
      width: AppDimensions.emergencyButtonSize,
      height: AppDimensions.emergencyButtonSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDisabled ? AppColors.mediumGray : AppColors.emergencyRed,
        boxShadow: isDisabled ? null : [
          BoxShadow(
            color: AppColors.emergencyRed.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(AppDimensions.emergencyButtonRadius),
          child: Center(
            child: _buildButtonContent(isEmergency: true),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent({bool isEmergency = false}) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isEmergency || variant == ButtonVariant.primary
                ? AppColors.textOnDark
                : AppColors.emergencyRed,
          ),
        ),
      );
    }

    final textWidget = Text(
      text,
      style: isEmergency ? AppTextStyles.emergencyButton : null,
      textAlign: TextAlign.center,
    );

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: _getIconSize()),
          const SizedBox(width: 8),
          Flexible(child: textWidget),
        ],
      );
    }

    return textWidget;
  }

  double _getButtonHeight() {
    switch (size) {
      case ButtonSize.small:
        return AppDimensions.buttonHeightS;
      case ButtonSize.medium:
        return AppDimensions.buttonHeightM;
      case ButtonSize.large:
        return AppDimensions.buttonHeightL;
      case ButtonSize.extraLarge:
        return AppDimensions.buttonHeightXL;
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case ButtonSize.small:
        return AppTextStyles.bodyMedium;
      case ButtonSize.medium:
        return AppTextStyles.buttonMedium;
      case ButtonSize.large:
      case ButtonSize.extraLarge:
        return AppTextStyles.buttonLarge;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return AppDimensions.iconS;
      case ButtonSize.medium:
        return AppDimensions.iconM;
      case ButtonSize.large:
      case ButtonSize.extraLarge:
        return AppDimensions.iconL;
    }
  }
}

enum ButtonVariant {
  primary,
  secondary,
  text,
  emergency,
}

enum ButtonSize {
  small,
  medium,
  large,
  extraLarge,
}