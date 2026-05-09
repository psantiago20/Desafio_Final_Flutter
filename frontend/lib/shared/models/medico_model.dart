class MedicoModel {
  final int id;
  final String nomeCompleto;
  final String crm;
  final String crmEstado;
  final String especialidade;
  final String? email;
  final String? telefone;
  final String? cidade;
  final String? endereco;
  final String? bioResumida;
  final String? fotoUrl;
  final double? valorConsulta;
  final bool aceitaConvenio;

  MedicoModel({
    required this.id,
    required this.nomeCompleto,
    required this.crm,
    required this.crmEstado,
    required this.especialidade,
    this.email,
    this.telefone,
    this.cidade,
    this.endereco,
    this.bioResumida,
    this.fotoUrl,
    this.valorConsulta,
    this.aceitaConvenio = false,
  });

  factory MedicoModel.fromJson(Map<String, dynamic> json) {
    return MedicoModel(
      id: json['id'],
      nomeCompleto: json['nome_completo'],
      crm: json['crm'],
      crmEstado: json['crm_estado'],
      especialidade: json['especialidade'],
      email: json['email'],
      telefone: json['telefone'],
      cidade: json['cidade'],
      endereco: json['endereco'],
      bioResumida: json['bio_resumida'],
      fotoUrl: json['foto_url'],
      valorConsulta: json['valor_consulta'] != null ? (json['valor_consulta'] as num).toDouble() : null,
      aceitaConvenio: json['aceita_convenio'] ?? false,
    );
  }
}
