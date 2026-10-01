/// Result of [AppInfoGenerator.generate].
class AppInfoResult {
  final String outputPath;
  final String className;
  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;
  final String fullVersion;
  final String? gitHash;
  final String? buildTimestamp;

  const AppInfoResult({
    required this.outputPath,
    required this.className,
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
    required this.fullVersion,
    this.gitHash,
    this.buildTimestamp,
  });

  @override
  String toString() {
    final buf = StringBuffer()
      ..writeln('✅ Generated $outputPath')
      ..writeln('   className:   $className')
      ..writeln('   appName:     $appName')
      ..writeln('   packageName: $packageName')
      ..writeln('   version:     $version')
      ..writeln('   buildNumber: $buildNumber');
    if (gitHash != null) buf.writeln('   gitHash:     $gitHash');
    if (buildTimestamp != null) {
      buf.writeln('   timestamp:   $buildTimestamp');
    }
    return buf.toString().trimRight();
  }
}
