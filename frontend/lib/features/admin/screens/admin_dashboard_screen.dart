import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_client.dart';
import '../../../features/auth/providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;
  int _selectedSidebarIndex = 0;

  // Cores baseadas no HTML fornecido
  final _surfaceColor = const Color(0xFFF7F9FB);
  final _surfaceLowest = const Color(0xFFFFFFFF);
  final _primaryColor = const Color(0xFF0052CC);
  final _primaryDark = const Color(0xFF003D9B);
  final _primaryFixed = const Color(0xFFDAE2FF);
  final _secondaryColor = const Color(0xFF006C4D);
  final _errorColor = const Color(0xFFBA1A1A);
  final _surfaceLow = const Color(0xFFF2F4F6);
  final _surfaceHigh = const Color(0xFFE6E8EA);
  final _textColor = const Color(0xFF191C1E);
  final _textVariant = const Color(0xFF434654);
  final _outlineColor = const Color(0xFF737685);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiClient.get('/api/simulator/data');
      setState(() {
        _data = response['data'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar dados: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem(String table, int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirmar Exclusão',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Deseja realmente excluir "$name"? Esta ação é irreversível e pode afetar registros vinculados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiClient.delete('/api/simulator/delete/$table/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name excluído com sucesso!'),
            backgroundColor: _secondaryColor,
          ),
        );
        _fetchData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir: $e'),
            backgroundColor: _errorColor,
          ),
        );
      }
    }
  }

  Future<void> _showEditDialog(String type, Map<String, dynamic> item) async {
    final formKey = GlobalKey<FormState>();
    final Map<String, dynamic> editData = {};

    List<Widget> fields = [];
    if (type == 'usuarios') {
      String name = item['full_name'] ?? item['username'] ?? '';
      String email = item['email'] ?? '';
      String role = item['role'] ?? 'user';
      bool isActive = item['is_active'] ?? true;

      fields = [
        TextFormField(
          initialValue: name,
          decoration: const InputDecoration(labelText: 'Nome Completo'),
          onSaved: (v) => editData['full_name'] = v,
        ),
        TextFormField(
          initialValue: email,
          decoration: const InputDecoration(labelText: 'E-mail'),
          onSaved: (v) => editData['email'] = v,
        ),
        DropdownButtonFormField<String>(
          initialValue: role,
          decoration: const InputDecoration(labelText: 'Papel'),
          items: const [
            DropdownMenuItem(value: 'admin', child: Text('Admin')),
            DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
            DropdownMenuItem(value: 'user', child: Text('User')),
          ],
          onChanged: (v) => editData['role'] = v,
          onSaved: (v) => editData['role'] = v,
        ),
        StatefulBuilder(
          builder: (context, setStateSB) {
            return SwitchListTile(
              title: const Text('Conta Ativa'),
              value: isActive,
              onChanged: (v) {
                setStateSB(() => isActive = v);
                editData['is_active'] = v;
              },
            );
          },
        ),
      ];
      editData['is_active'] = isActive; // default if untouched
    } else if (type == 'medicos') {
      fields = [
        TextFormField(
          initialValue: item['nome'],
          decoration: const InputDecoration(labelText: 'Nome'),
          onSaved: (v) => editData['nome'] = v,
        ),
        TextFormField(
          initialValue: item['crm'],
          decoration: const InputDecoration(labelText: 'CRM/UF'),
          onSaved: (v) => editData['crm'] = v,
        ),
        TextFormField(
          initialValue: item['especialidade'],
          decoration: const InputDecoration(labelText: 'Especialidade'),
          onSaved: (v) => editData['especialidade'] = v,
        ),
        TextFormField(
          initialValue: item['telefone'],
          decoration: const InputDecoration(labelText: 'Telefone'),
          onSaved: (v) => editData['telefone'] = v,
        ),
        TextFormField(
          initialValue: item['cidade'],
          decoration: const InputDecoration(labelText: 'Cidade'),
          onSaved: (v) => editData['cidade'] = v,
        ),
      ];
    } else if (type == 'pacientes') {
      fields = [
        TextFormField(
          initialValue: item['nome'],
          decoration: const InputDecoration(labelText: 'Nome'),
          onSaved: (v) => editData['nome'] = v,
        ),
        TextFormField(
          initialValue: item['cpf'],
          decoration: const InputDecoration(labelText: 'CPF'),
          onSaved: (v) => editData['cpf'] = v,
        ),
        TextFormField(
          initialValue: item['whatsapp'],
          decoration: const InputDecoration(labelText: 'WhatsApp'),
          onSaved: (v) => editData['whatsapp'] = v,
        ),
        TextFormField(
          initialValue: item['cidade'],
          decoration: const InputDecoration(labelText: 'Cidade'),
          onSaved: (v) => editData['cidade'] = v,
        ),
      ];
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Editar ${type.toUpperCase()}',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: fields),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              formKey.currentState?.save();
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiClient.put('/api/simulator/edit/$type/${item['id']}', {
          'data': editData,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Registro atualizado!'),
              backgroundColor: _secondaryColor,
            ),
          );
          _fetchData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: _errorColor),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;

    return Scaffold(
      backgroundColor: _surfaceColor,
      body: Column(
        children: [
          _buildTopNavigation(isDesktop),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDesktop) _buildSidebar(),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: _primaryColor,
                          ),
                        )
                      : _error != null
                      ? _buildErrorView()
                      : _buildMainContent(isDesktop),
                ),
              ],
            ),
          ),
          if (!isDesktop) _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildTopNavigation(bool isDesktop) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: _surfaceLowest.withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: _textColor.withValues(alpha: 0.06),
            blurRadius: 40,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primaryFixed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.admin_panel_settings, color: _primaryColor),
              ),
              const SizedBox(width: 16),
              Text(
                'Sua Consulta',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _primaryColor,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          if (isDesktop)
            Row(
              children: [
                _buildTopNavLink('Admin do Sistema', isActive: true),
                const SizedBox(width: 32),
                _buildTopNavLink('Analytics Global'),
                const SizedBox(width: 32),
                _buildTopNavLink('Logs de Auditoria'),
              ],
            ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none, color: _textVariant),
                onPressed: () {},
              ),
              const SizedBox(width: 12),
              if (isDesktop)
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                  },
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text('Sair'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _errorColor.withValues(alpha: 0.1),
                    foregroundColor: _errorColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavLink(String text, {bool isActive = false}) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
        color: isActive ? _primaryColor : _textVariant,
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        boxShadow: [
          BoxShadow(
            color: _textColor.withValues(alpha: 0.04),
            blurRadius: 40,
            offset: const Offset(10, 0),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.admin_panel_settings, color: _primaryColor),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Controle do Sistema',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  Text(
                    'Gestão da Plataforma',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _textVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSidebarItem(0, Icons.group, 'Gerenciamento de Usuários'),
          _buildSidebarItem(
            1,
            Icons.medical_services_outlined,
            'Diretório de Médicos',
          ),
          _buildSidebarItem(2, Icons.person_outline, 'Diretório de Pacientes'),
          _buildSidebarItem(
            3,
            Icons.settings_suggest_outlined,
            'Configurações do Sistema',
          ),
          _buildSidebarItem(4, Icons.help_outline, 'Suporte e Ajuda'),
          const Spacer(),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STATUS GLOBAL',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _outlineColor,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'v2.4.0-admin',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _secondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String title) {
    final isSelected = _selectedSidebarIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedSidebarIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected ? _surfaceLow : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? _primaryColor : _textVariant,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? _primaryColor : _textVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: _surfaceLowest.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: _textColor.withValues(alpha: 0.06),
            blurRadius: 40,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(0, Icons.group, 'Usuários'),
          _buildBottomNavItem(1, Icons.medical_services_outlined, 'Médicos'),
          _buildBottomNavItem(2, Icons.person_outline, 'Pacientes'),
          _buildBottomNavItem(
            3,
            Icons.settings_suggest,
            'Sistema',
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(
    int index,
    IconData icon,
    String label, {
    bool isPrimary = false,
  }) {
    final isSelected = _selectedSidebarIndex == index && !isPrimary;

    if (isPrimary) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [_primaryDark, _primaryColor]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => setState(() => _selectedSidebarIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? _primaryColor : _textVariant,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isSelected ? _primaryColor : _textVariant,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: _errorColor),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: GoogleFonts.inter(
              color: _errorColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchData,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isDesktop) {
    final usuarios = (_data?['usuarios'] as List?) ?? [];
    final medicos = (_data?['medicos'] as List?) ?? [];
    final pacientes = (_data?['pacientes'] as List?) ?? [];

    List<dynamic> activeList = [];
    String activeTitle = '';
    String tableType = 'usuarios';

    switch (_selectedSidebarIndex) {
      case 0:
        activeList = usuarios;
        activeTitle = 'Gerenciamento de Usuários';
        tableType = 'usuarios';
        break;
      case 1:
        activeList = medicos;
        activeTitle = 'Diretório de Médicos';
        tableType = 'medicos';
        break;
      case 2:
        activeList = pacientes;
        activeTitle = 'Diretório de Pacientes';
        tableType = 'pacientes';
        break;
      default:
        activeList = usuarios;
        activeTitle = 'Gerenciamento Geral';
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 32 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Portal do Sistema',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _textVariant,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: _textVariant,
                        ),
                        Text(
                          activeTitle,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Administração da Plataforma',
                      style: GoogleFonts.manrope(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: _textColor,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Centro de controle global para acesso de usuários, monitoramento da saúde da plataforma e configurações do sistema.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _textVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDesktop)
                Row(
                  children: [
                    Container(
                      width: 280,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _surfaceLowest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: _outlineColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Buscar por ID, papel ou nome...',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: _outlineColor,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: _surfaceLowest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.filter_alt,
                          color: _textVariant,
                          size: 20,
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 32),

          // Bento Grid Stats
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 600;
              return GridView.count(
                crossAxisCount: isSmall ? 1 : 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: isSmall ? 2.5 : 1.5,
                children: [
                  _buildStatCard(
                    'Total de Usuários',
                    '${usuarios.length}',
                    '+12%',
                    _surfaceLowest,
                    _textColor,
                    _primaryColor,
                  ),
                  _buildStatCard(
                    'Médicos Ativos',
                    '${medicos.length}',
                    'na plataforma',
                    _surfaceLowest,
                    _textColor,
                    _textColor,
                    subtitleIsBadge: false,
                  ),
                  _buildStatCard(
                    'Saúde da Plataforma',
                    '99.9%',
                    'dns',
                    _primaryColor,
                    Colors.white,
                    Colors.white,
                    isIcon: true,
                  ),
                  _buildStatCard(
                    'Tempo de Atividade',
                    '42d',
                    'cloud_done',
                    _secondaryColor,
                    Colors.white,
                    Colors.white,
                    isIcon: true,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // Data Management Table
          Container(
            decoration: BoxDecoration(
              color: _surfaceLowest,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _textColor.withValues(alpha: 0.04),
                  blurRadius: 40,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                if (isDesktop) _buildTableHeader(tableType),
                if (activeList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Nenhum dado encontrado para esta seleção.',
                        style: GoogleFonts.inter(color: _textVariant),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeList.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: _surfaceLow),
                    itemBuilder: (context, index) =>
                        _buildRowItem(activeList[index], isDesktop, tableType),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: _surfaceLow.withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mostrando ${activeList.length} registros',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _textVariant,
                        ),
                      ),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: _outlineColor.withValues(alpha: 0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Anterior',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _textVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: _primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Próximo',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    Color bgColor,
    Color textColor,
    Color valueColor, {
    bool subtitleIsBadge = true,
    bool isIcon = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (bgColor != _surfaceLowest)
            BoxShadow(
              color: bgColor.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor.withValues(alpha: 0.6),
              letterSpacing: 1.5,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                  height: 1.1,
                ),
              ),
              if (isIcon)
                Icon(
                  subtitle == 'dns' ? Icons.dns : Icons.cloud_done,
                  color: textColor,
                )
              else if (subtitleIsBadge)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF86F8C8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF007352),
                    ),
                  ),
                )
              else
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _outlineColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      color: _surfaceLow,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildHeaderText(
              type == 'pacientes'
                  ? 'PERFIL DO PACIENTE'
                  : type == 'medicos'
                  ? 'PERFIL DO MÉDICO'
                  : 'PERFIL DO USUÁRIO',
            ),
          ),
          Expanded(
            flex: 1,
            child: _buildHeaderText(
              type == 'medicos' ? 'ESPECIALIDADE' : 'PAPEL NO SISTEMA',
            ),
          ),
          Expanded(flex: 1, child: _buildHeaderText('STATUS DA CONTA')),
          Expanded(
            flex: 1,
            child: _buildHeaderText(
              type == 'medicos' ? 'CRM / CONTATO' : 'NÍVEL DE SEGURANÇA',
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildHeaderText('CONTROLE DE ACESSO'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderText(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: _outlineColor,
        letterSpacing: 2.0,
      ),
    );
  }

  Widget _buildRowItem(Map<String, dynamic> item, bool isDesktop, String type) {
    final int id = item['id'] ?? 0;
    String name = '';
    String subName = '';
    String roleText = '';
    String statusText = 'Ativo';
    bool isActive = true;
    Widget securityOrContactSection;

    if (type == 'usuarios') {
      name = item['full_name'] ?? item['username'] ?? 'User';
      subName = item['email'] ?? 'UID: #AT-$id';
      roleText = item['role']?.toString().toUpperCase() ?? 'USER';
      isActive = item['is_active'] ?? true;
      statusText = isActive ? 'Ativo' : 'Suspenso';

      securityOrContactSection = Container(
        width: 100,
        height: 6,
        decoration: BoxDecoration(
          color: _surfaceHigh,
          borderRadius: BorderRadius.circular(4),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: isActive ? (roleText == 'ADMIN' ? 0.95 : 0.8) : 0.4,
          child: Container(
            decoration: BoxDecoration(
              color: isActive
                  ? (roleText == 'ADMIN' ? _secondaryColor : _primaryColor)
                  : _errorColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      );
    } else if (type == 'medicos') {
      name = item['nome'] ?? 'Médico';
      subName = item['cidade'] ?? 'Localização não informada';
      roleText = item['especialidade']?.toString().toUpperCase() ?? 'GERAL';
      String crm = item['crm'] ?? '';
      String tel = item['telefone'] ?? '';

      securityOrContactSection = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            crm,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
          Text(
            tel,
            style: GoogleFonts.inter(fontSize: 11, color: _outlineColor),
          ),
        ],
      );
    } else {
      // pacientes
      name = item['nome'] ?? 'Paciente';
      subName = item['cidade'] ?? 'Localização não informada';
      roleText = 'PACIENTE';
      String cpf = item['cpf'] ?? '';
      String whats = item['whatsapp'] ?? '';

      securityOrContactSection = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            cpf,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
          Text(
            whats,
            style: GoogleFonts.inter(fontSize: 11, color: _outlineColor),
          ),
        ],
      );
    }

    Color roleBgColor = _surfaceHigh;
    Color roleTextColor = _textVariant;

    if (roleText == 'ADMIN') {
      roleBgColor = _primaryFixed;
      roleTextColor = const Color(0xFF0040A2);
    } else if (roleText == 'DOCTOR' || type == 'medicos') {
      roleBgColor = const Color(0xFF86F8C8);
      roleTextColor = const Color(0xFF007352);
    } else if (type == 'pacientes') {
      roleBgColor = const Color(0xFFFFDBCF);
      roleTextColor = const Color(0xFF812800);
    }

    Widget profileSection = Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _surfaceHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subName,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _textVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

    Widget roleSection = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: roleBgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        roleText,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: roleTextColor,
        ),
      ),
    );

    Widget statusSection = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? _secondaryColor : _errorColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          statusText,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textColor,
          ),
        ),
      ],
    );

    Widget actionsSection = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: Icon(Icons.edit, color: _primaryColor, size: 20),
          onPressed: () => _showEditDialog(type, item),
          tooltip: 'Editar Cadastro',
        ),
        IconButton(
          icon: Icon(Icons.block, color: _errorColor, size: 20),
          onPressed: () => _deleteItem(type, id, name),
          tooltip: 'Excluir Definitivamente',
        ),
      ],
    );

    if (!isDesktop) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: profileSection),
                roleSection,
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [statusSection, actionsSection],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Row(
        children: [
          Expanded(flex: 2, child: profileSection),
          Expanded(
            flex: 1,
            child: Align(alignment: Alignment.centerLeft, child: roleSection),
          ),
          Expanded(flex: 1, child: statusSection),
          Expanded(flex: 1, child: securityOrContactSection),
          Expanded(flex: 1, child: actionsSection),
        ],
      ),
    );
  }
}
