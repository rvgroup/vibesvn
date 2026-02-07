import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../models/repository.dart';
import '../services/storage_service.dart';
import '../services/svn_service.dart';
import '../services/window_service.dart';
import 'repository_dialogs.dart';
import 'commit_screen.dart';
import 'advanced_settings_dialog.dart';
import 'settings_screen.dart';
import '../helpers/link_helper.dart';
import '../widgets/clickable_text.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<SvnRepository> repositories = [];

  @override
  void initState() {
    super.initState();
    _loadRepositories();
  }

  Future<void> _loadRepositories() async {
    final repos = await StorageService.getRepositories();
    
    // Обновляем ревизии для каждого репозитория
    final updatedRepos = <SvnRepository>[];
    for (final repo in repos) {
      final revision = await SvnService.getCurrentRevision(repo.localPath);
      final updatedRepo = repo.copyWith(currentRevision: revision);
      updatedRepos.add(updatedRepo);
    }
    
    setState(() {
      repositories = updatedRepos;
    });
  }

  void _showCreateRepositoryDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateRepositoryDialog(
        onRepositoryCreated: _loadRepositories,
      ),
    );
  }

  void _showOpenRepositoryDialog() {
    showDialog(
      context: context,
      builder: (context) => OpenRepositoryDialog(
        onRepositoryOpened: _loadRepositories,
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }

  void _showAdvancedSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => const AdvancedSettingsDialog(),
    );
  }

  void _openCommitScreen(SvnRepository repository) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommitScreen(repository: repository),
      ),
    ).then((_) => _loadRepositories());
  }

  Future<void> _deleteRepository(SvnRepository repository) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Repository'.tr()),
        content: Text('Are you sure you want to remove repository "{name}" from the list?'.tr().replaceAll('{name}', repository.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.removeRepository(repository.id);
      _loadRepositories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VibeSVN'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () => WindowService.toggleMaximize(),
            icon: FutureBuilder<bool>(
              future: WindowService.isMaximized(),
              builder: (context, snapshot) {
                final isMaximized = snapshot.data ?? false;
                return Icon(isMaximized ? Icons.fullscreen_exit : Icons.fullscreen);
              },
            ),
            tooltip: 'Maximize/Restore'.tr(),
          ),
          IconButton(
            onPressed: () => WindowService.minimize(),
            icon: const Icon(Icons.minimize),
            tooltip: 'Minimize'.tr(),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings),
                    const SizedBox(width: 8),
                    Text('Settings'.tr()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    const Icon(Icons.restore),
                    const SizedBox(width: 8),
                    Text('Reset Window Size'.tr()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'center',
                child: Row(
                  children: [
                    const Icon(Icons.center_focus_strong),
                    const SizedBox(width: 8),
                    Text('Center Window'.tr()),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                  break;
                case 'reset':
                  WindowService.resetWindowState();
                  break;
                case 'center':
                  WindowService.centerWindow();
                  break;
              }
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Левая панель действий
          Container(
            width: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: ActionPanel(
              onCreateRepository: _showCreateRepositoryDialog,
              onOpenRepository: _showOpenRepositoryDialog,
              onSettings: _showSettingsDialog,
              onAdvancedSettings: _showAdvancedSettingsDialog,
            ),
          ),
          // Правая область репозиториев
          Expanded(
            child: RepositoryList(
              repositories: repositories,
              onOpenRepository: _openCommitScreen,
              onDeleteRepository: _deleteRepository,
            ),
          ),
        ],
      ),
    );
  }
}

class ActionPanel extends StatelessWidget {
  final VoidCallback onCreateRepository;
  final VoidCallback onOpenRepository;
  final VoidCallback onSettings;
  final VoidCallback onAdvancedSettings;

  const ActionPanel({
    super.key,
    required this.onCreateRepository,
    required this.onOpenRepository,
    required this.onSettings,
    required this.onAdvancedSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions'.tr(),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          context,
          'Create Repository'.tr(),
          Icons.download,
          onCreateRepository,
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          context,
          'Open Local Repository'.tr(),
          Icons.folder_open,
          onOpenRepository,
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          context,
          'User Settings'.tr(),
          Icons.settings,
          onSettings,
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          context,
          'Advanced Settings'.tr(),
          Icons.tune,
          onAdvancedSettings,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}

class RepositoryList extends StatelessWidget {
  final List<SvnRepository> repositories;
  final Function(SvnRepository) onOpenRepository;
  final Function(SvnRepository) onDeleteRepository;

  const RepositoryList({
    super.key,
    required this.repositories,
    required this.onOpenRepository,
    required this.onDeleteRepository,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Working Repositories'.tr(),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          if (repositories.isEmpty)
            Center(
              child: Text(
                'No working repositories'.tr(),
                style: const TextStyle(color: Colors.grey),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: repositories.length,
                itemBuilder: (context, index) {
                  final repository = repositories[index];
                  return RepositoryCard(
                    repository: repository,
                    onOpen: () => onOpenRepository(repository),
                    onDelete: () => onDeleteRepository(repository),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class RepositoryCard extends StatefulWidget {
  final SvnRepository repository;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const RepositoryCard({
    super.key,
    required this.repository,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  State<RepositoryCard> createState() => _RepositoryCardState();
}

class _RepositoryCardState extends State<RepositoryCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Double click to open repository'.tr(),
      child: GestureDetector(
        onDoubleTap: () {
          setState(() {
            _isPressed = true;
          });
          
          // Add haptic feedback if available
          // HapticFeedback.lightImpact();
          
          // Small delay for visual feedback
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted) {
              setState(() {
                _isPressed = false;
              });
            }
          });
          
          widget.onOpen();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(_isPressed ? 0.3 : 0.1),
                blurRadius: _isPressed ? 8 : 4,
                offset: Offset(0, _isPressed ? 2 : 1),
              ),
            ],
          ),
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: _isPressed 
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.repository.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: _isPressed 
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              widget.repository.currentRevision != null 
                                  ? 'r${widget.repository.currentRevision}'
                                  : 'Unknown'.tr(),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: widget.repository.currentRevision != null
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClickableText(
                                text: widget.repository.localPath,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey,
                                    ),
                                onTap: () async {
                                  await LinkHelper.openLink(widget.repository.localPath);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClickableText(
                          text: widget.repository.remoteUrl,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: widget.onOpen,
                        icon: const Icon(Icons.open_in_new),
                        tooltip: 'Open'.tr(),
                      ),
                      IconButton(
                        onPressed: widget.onDelete,
                        icon: const Icon(Icons.delete),
                        tooltip: 'Delete'.tr(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
