/// Normaliza telefone para o mesmo formato usado pelo WhatsApp (Meta): só dígitos, com DDI.
String canonicalWaFrom(String? phone) {
  if (phone == null || phone.isEmpty) return '';
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  return digits;
}
