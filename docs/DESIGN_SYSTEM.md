# Design System: OmniConnect (Sua Consulta) 🎨

Este documento serve como a fonte de verdade para a equipe de desenvolvimento (Front-end e UI/UX) sobre os padrões visuais aplicados ao aplicativo Sua Consulta. O design foi construído seguindo princípios de **Clean UI** e **Glassmorphism**, garantindo uma experiência premium.

## 1. 🌈 Paleta de Cores Oficial

A paleta principal baseia-se em 7 tons de Azul, aplicados para manter contraste e harmonia, com tons de suporte para feedbacks do sistema.

### Tons de Azul (Primary & Secondary)
| Cor                  | Hexadecimal | Uso Principal                                      |
|----------------------|-------------|----------------------------------------------------|
| **Primary Blue Dark**| `#001D39`   | Textos principais, Títulos da AppBar, Ícones ativos|
| **Primary Blue**     | `#0A4174`   | Botões primários, Fundo de balão de Chat (isMe)    |
| **Primary Blue Light**| `#BDD8E9`  | Fundos secundários, Cards de destaque              |
| **Secondary Blue Dark**| `#49769F` | Elementos de suporte secundários                   |
| **Secondary Blue**   | `#4E8EA2`   | Gradientes, detalhes secundários                   |
| **Secondary Blue Light**|`#6EA2B3` | Destaques sutis                                    |
| **Accent Blue**      | `#7BBDE8`   | Links, ícones de ação                              |

### Cores de Fundo e Superfícies (Neutras)
- **Background Gradient:** `LinearGradient` de `#F0F4F8` para `#F9FAFB` (Top to Bottom).
- **Surface White:** `#FFFFFF` (Fundo de Cards, AppBar, Inputs de Texto).
- **Background Gray:** `#F9FAFB` (Scaffold padrão).
- **Border Gray:** `#E5E7EB` (Bordas de Cards e Divisores).

### Textos (Hierarquia)
- **Text Primary:** `#111827` (Textos escuros de alta leitura).
- **Text Secondary:** `#4B5563` (Subtítulos).
- **Text Tertiary:** `#6B7280` (Textos de apoio, horários de consultas).

### Feedbacks de Sistema
- **Success Green:** `#16A34A` (Tags de "Concluído", "Sucesso").
- **Warning Orange:** `#EA580C` (Tags de "Pendente", "Aguardando").
- **Alert Red:** `#EF4444` (Botões de "Cancelar", "Aviso").

---

## 2. 🧱 Arquitetura de Componentes

### Estilo "Pílula" (Border Radius)
Nenhum elemento da interface deve usar bordas afiadas (`0px`).
- **Botões Grandes (ElevatedButton):** `borderRadius: 32px`.
- **Cartões (Cards):** `borderRadius: 24px`.
- **Chips e Filtros (ChoiceChip):** `borderRadius: 20px`.
- **Inputs de Texto (TextField):** `borderRadius: 24px`.

### Barra de Navegação (Navigation Bar)
- Foi adotado o padrão **Material 3 `NavigationBar`**, substituindo a antiga `BottomNavigationBar`.
- Isso garante o efeito de indicador flutuante arredondado (pílula) quando uma aba é selecionada.

### Barra de Topo (Custom AppBar)
- Padrão **Transparente/Clean**: A AppBar deve ter `backgroundColor: Colors.transparent` ou `surfaceWhite`, sem sombras (`elevation: 0`).
- Textos e Ícones da AppBar utilizam o `primaryBlueDark` (`#001D39`) para máximo contraste.

## 3. 🖥️ Implementação no Código (Flutter)

Toda a lógica de tema centralizada deve ser importada de um único arquivo. 
A equipe **NÃO DEVE** usar cores *hardcoded* (ex: `Colors.blue`) nas telas. Use sempre o `AppTheme`:

```dart
import '../../theme/app_theme.dart';

// ❌ Errado:
Container(color: Colors.blue[900]);

// ✅ Certo:
Container(color: AppTheme.primaryBlueDark);
```
