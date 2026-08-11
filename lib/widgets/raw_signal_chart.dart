import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class _SignalPoint {
  const _SignalPoint(this.timeSeconds, this.amplitude);

  final double timeSeconds;
  final double amplitude;
}

class RawSignalChart extends StatelessWidget {
  const RawSignalChart({
    super.key,
    required this.samples,
    required this.title,
    this.subtitle,
    this.height = 180,
    this.chartWidth,
    this.fixedXMin = 0,
    this.fixedXMax = 20,
    this.fixedYMin = -2000,
    this.fixedYMax = 2000,
  });

  final List<double> samples;
  final String title;
  final String? subtitle;
  final double height;
  final double? chartWidth;
  final double fixedXMin;
  final double fixedXMax;
  final double fixedYMin;
  final double fixedYMax;

  @override
  Widget build(BuildContext context) {
    final points = samples.asMap().entries.map((entry) {
      final index = entry.key;
      final sampleCount = samples.length;
      final timeSeconds = sampleCount <= 1
          ? 0.0
          : (index * 20.0) / (sampleCount - 1);
      return _SignalPoint(timeSeconds, entry.value);
    }).toList(growable: false);

    return Container(
      width: chartWidth ?? double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0850FD).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.multiline_chart_rounded,
                  color: Color(0xFF0850FD),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: height,
            child: points.isEmpty
                ? Center(
                    child: Text(
                      'Waiting for raw signal...',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 13,
                      ),
                    ),
                  )
                : SfCartesianChart(
                    plotAreaBorderWidth: 0,
                    margin: const EdgeInsets.only(left: 4, right: 12, top: 8),
                    backgroundColor: Colors.transparent,
                    title: ChartTitle(
                      text: 'EEG Waveform',
                      textStyle: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    primaryXAxis: NumericAxis(
                      minimum: fixedXMin,
                      maximum: fixedXMax,
                      interval: 5,
                      edgeLabelPlacement: EdgeLabelPlacement.shift,
                      labelRotation: 0,
                      title: AxisTitle(
                        text: 'Time (seconds)',
                        textStyle: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                        ),
                      ),
                      labelStyle: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10,
                      ),
                      majorGridLines: MajorGridLines(
                        width: 0.6,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      axisLine: AxisLine(
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                      majorTickLines: MajorTickLines(
                        size: 4,
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    primaryYAxis: NumericAxis(
                      minimum: fixedYMin,
                      maximum: fixedYMax,
                      title: AxisTitle(
                        text: 'Amplitude (µV)',
                        textStyle: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                        ),
                      ),
                      labelStyle: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10,
                      ),
                      majorGridLines: MajorGridLines(
                        width: 0.6,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      axisLine: AxisLine(
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                      majorTickLines: MajorTickLines(
                        size: 4,
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    series: <LineSeries<_SignalPoint, double>>[
                      LineSeries<_SignalPoint, double>(
                        dataSource: points,
                        xValueMapper: (value, _) => value.timeSeconds,
                        yValueMapper: (value, _) => value.amplitude,
                        width: 2.2,
                        color: const Color(0xFF5B7CFA),
                        animationDuration: 0,
                        markerSettings: const MarkerSettings(
                          isVisible: false,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}