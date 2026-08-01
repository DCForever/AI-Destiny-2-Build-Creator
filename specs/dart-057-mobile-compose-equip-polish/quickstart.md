# Quickstart: DART-057

## Branch

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
git checkout dart-057-mobile-compose-equip-polish
```

## Tests

```powershell
# Mobile matrix + shell
cd apps\mobile_host
flutter test test/surface_matrix_test.dart test/shell_nav_test.dart test/finish_gaps_format_test.dart

# Windows finish + CTA format
cd ..\windows_host
flutter test test/finish_gaps_format_test.dart test/equip_format_test.dart test/dim_export_format_test.dart

# Jaspr soft stats + finish
cd ..\web_host
dart test test/soft_guidance_format_test.dart test/finish_gaps_format_test.dart test/equip_format_test.dart test/dim_export_format_test.dart
```

## Manual smoke

1. **Mobile**: Open app → Builds | Settings only → Settings shows surface matrix with equip/DIM N/A.
2. **Jaspr**: Open build compose → Soft guidance shows six stat fields → Save multi targets → summary lists them.
3. **Windows/Jaspr**: Open build with empty finish → Finish panel shows needs_set; Apply/Copy disabled even if pins later equip-ready until finish complete.
