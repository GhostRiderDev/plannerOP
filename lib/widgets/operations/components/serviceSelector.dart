import 'package:flutter/material.dart';
import 'package:plannerop/core/model/task.dart';
import 'package:plannerop/core/model/subtask.dart';
import 'package:plannerop/widgets/operations/components/utils/Button.dart';

/// Selector de servicios mejorado con categorías y subcategorías
Widget buildServiceSelector(
  BuildContext context,
  List<Task> availableTasks,
  int selectedSubtaskId,
  Function(SubTask) onSubtaskChanged,
) {
  // Encontrar la subtarea seleccionada
  SubTask? selectedSubtask;
  Task? parentTask;

  for (final task in availableTasks) {
    for (final subtask in task.subtasks) {
      if (subtask.id == selectedSubtaskId) {
        selectedSubtask = subtask;
        parentTask = task;
        break;
      }
    }
    if (selectedSubtask != null) break;
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Servicio para este grupo',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: () {
          _showHierarchicalServiceSelector(
            context,
            availableTasks,
            selectedSubtaskId,
            onSubtaskChanged,
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: selectedSubtask == null
                    ? const Text(
                        'Toca para seleccionar servicio',
                        style: TextStyle(
                          color: Color(0xFF718096),
                          fontSize: 14,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${selectedSubtask.code} - ${selectedSubtask.name}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Categoría: ${parentTask?.name ?? ""}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

/// Modal con vista jerárquica de categorías y subcategorías
void _showHierarchicalServiceSelector(
  BuildContext context,
  List<Task> availableTasks,
  int? initialSelection,
  Function(SubTask) onSubtaskSelected,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ServiceSelectorModal(
      availableTasks: availableTasks,
      initialSelection: initialSelection,
      onSubtaskSelected: onSubtaskSelected,
    ),
  );
}

class _ServiceSelectorModal extends StatefulWidget {
  final List<Task> availableTasks;
  final int? initialSelection;
  final Function(SubTask) onSubtaskSelected;

  const _ServiceSelectorModal({
    required this.availableTasks,
    required this.initialSelection,
    required this.onSubtaskSelected,
  });

  @override
  State<_ServiceSelectorModal> createState() => _ServiceSelectorModalState();
}

class _ServiceSelectorModalState extends State<_ServiceSelectorModal> {
  int? _selectedSubtaskId;
  String _searchQuery = '';
  bool _isSearchMode = false;
  List<_SearchResult> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _selectedSubtaskId = widget.initialSelection;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(
            child: _isSearchMode ? _buildSearchResults() : _buildCategoryView(),
          ),
          _buildConfirmButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Seleccionar servicio',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (_selectedSubtaskId != null)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedSubtaskId = null;
                });
              },
              child: const Text(
                'Limpiar',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar por código o nombre...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _clearSearch(),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildCategoryView() {
    return ListView.builder(
      itemCount: widget.availableTasks.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final task = widget.availableTasks[index];
        return _CategoryTile(
          task: task,
          selectedSubtaskId: _selectedSubtaskId,
          onSubtaskSelected: (subtaskId) {
            setState(() {
              _selectedSubtaskId = subtaskId;
            });
          },
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return _buildEmptySearchResults();
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        final isSelected = _selectedSubtaskId == result.subtask.id;

        return ListTile(
          title: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87),
              children: [
                TextSpan(
                  text: result.subtask.code,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.blue.shade800 : Colors.black87,
                  ),
                ),
                const TextSpan(text: ' - '),
                TextSpan(
                  text: result.subtask.name,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.blue.shade800 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          subtitle: Text(
            'Categoría: ${result.parentTask.name}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          trailing: isSelected
              ? Icon(Icons.radio_button_checked, color: Colors.blue.shade700)
              : Icon(Icons.radio_button_unchecked, color: Colors.grey.shade400),
          onTap: () {
            setState(() {
              _selectedSubtaskId = isSelected ? null : result.subtask.id;
            });
          },
        );
      },
    );
  }

  Widget _buildEmptySearchResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron servicios para "$_searchQuery"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta buscar por código o nombre del servicio',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AppButton(
        text: _selectedSubtaskId != null
            ? 'Confirmar selección'
            : 'Selecciona un servicio',
        onPressed: _selectedSubtaskId != null
            ? () {
                final selectedSubtask = widget.availableTasks
                    .expand((task) => task.subtasks)
                    .firstWhere((subtask) => subtask.id == _selectedSubtaskId);
                widget.onSubtaskSelected(selectedSubtask);
                Navigator.pop(context);
              }
            : null,
        isFullWidth: true,
      ),
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _isSearchMode = query.isNotEmpty;

      if (_isSearchMode) {
        _searchResults = _performSearch(query);
      }
    });
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _isSearchMode = false;
      _searchResults = [];
    });
  }

  List<_SearchResult> _performSearch(String query) {
    final results = <_SearchResult>[];
    final lowerQuery = query.toLowerCase();

    for (final task in widget.availableTasks) {
      for (final subtask in task.subtasks) {
        final matchesCode = subtask.code.toLowerCase().contains(lowerQuery);
        final matchesName = subtask.name.toLowerCase().contains(lowerQuery);

        if (matchesCode || matchesName) {
          results.add(_SearchResult(
            parentTask: task,
            subtask: subtask,
          ));
        }
      }
    }

    return results;
  }
}

/// Widget para mostrar una categoría con sus subcategorías
class _CategoryTile extends StatefulWidget {
  final Task task;
  final int? selectedSubtaskId;
  final Function(int) onSubtaskSelected;

  const _CategoryTile({
    required this.task,
    required this.selectedSubtaskId,
    required this.onSubtaskSelected,
  });

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Expandir automáticamente si contiene la subtarea seleccionada
    _isExpanded = widget.task.subtasks.any(
      (subtask) => subtask.id == widget.selectedSubtaskId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelectedSubtask = widget.task.subtasks.any(
      (subtask) => subtask.id == widget.selectedSubtaskId,
    );

    return Column(
      children: [
        ListTile(
          leading: Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
            color: hasSelectedSubtask
                ? Colors.blue.shade700
                : Colors.grey.shade600,
          ),
          title: Text(
            widget.task.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: hasSelectedSubtask ? Colors.blue.shade800 : Colors.black87,
            ),
          ),
          subtitle: Text(
            '${widget.task.subtasks.length} servicios disponibles',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          trailing: hasSelectedSubtask
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
        ),
        if (_isExpanded)
          ...widget.task.subtasks.map((subtask) {
            final isSelected = widget.selectedSubtaskId == subtask.id;

            return Padding(
              padding: const EdgeInsets.only(left: 32),
              child: ListTile(
                dense: true,
                title: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87),
                    children: [
                      TextSpan(
                        text: subtask.code,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.blue.shade800
                              : Colors.black87,
                        ),
                      ),
                      const TextSpan(text: ' - '),
                      TextSpan(
                        text: subtask.name,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? Colors.blue.shade800
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.radio_button_checked,
                        color: Colors.blue.shade700)
                    : Icon(Icons.radio_button_unchecked,
                        color: Colors.grey.shade400),
                onTap: () {
                  widget.onSubtaskSelected(isSelected ? 0 : subtask.id);
                },
              ),
            );
          }).toList(),
        const Divider(height: 1),
      ],
    );
  }
}

/// Clase auxiliar para resultados de búsqueda
class _SearchResult {
  final Task parentTask;
  final SubTask subtask;

  _SearchResult({
    required this.parentTask,
    required this.subtask,
  });
}
