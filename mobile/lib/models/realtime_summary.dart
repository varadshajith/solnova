class RealtimeSummary {
  final double consumptionKW;
  final double generationKW;
  final double batterySoc;

  // Optional extended telemetry (if backend provides them)
  final double? dcBusVoltageV;
  final double? dcBusCurrentA;
  final double? acVoltageV;
  final double? acFrequencyHz;
  final bool? gridTieConnected;
  final double? equipmentTempC;
  final double? solarIrradiance;
  final double? ambientTempC;
  final double? humidityPct;

  const RealtimeSummary({
    required this.consumptionKW,
    required this.generationKW,
    required this.batterySoc,
    this.dcBusVoltageV,
    this.dcBusCurrentA,
    this.acVoltageV,
    this.acFrequencyHz,
    this.gridTieConnected,
    this.equipmentTempC,
    this.solarIrradiance,
    this.ambientTempC,
    this.humidityPct,
  });

  factory RealtimeSummary.fromJson(Map<String, dynamic> j) => RealtimeSummary(
        consumptionKW: (j['consumption_kW'] as num).toDouble(),
        generationKW: (j['generation_kW'] as num).toDouble(),
        batterySoc: (j['battery_soc'] as num).toDouble(),
        dcBusVoltageV: (j['dc_bus_voltage_v'] as num?)?.toDouble() ?? (j['dc_bus_voltage'] as num?)?.toDouble(),
        dcBusCurrentA: (j['dc_bus_current_a'] as num?)?.toDouble() ?? (j['dc_bus_current'] as num?)?.toDouble(),
        acVoltageV: (j['ac_voltage_v'] as num?)?.toDouble(),
        acFrequencyHz: (j['ac_frequency_hz'] as num?)?.toDouble(),
        gridTieConnected: j['grid_tie_connected'] as bool?,
        equipmentTempC: (j['equipment_temp_c'] as num?)?.toDouble(),
        solarIrradiance: (j['solar_irradiance'] as num?)?.toDouble(),
        ambientTempC: (j['ambient_temp_c'] as num?)?.toDouble(),
        humidityPct: (j['humidity_pct'] as num?)?.toDouble(),
      );
}
