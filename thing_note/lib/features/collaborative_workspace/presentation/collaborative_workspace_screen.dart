import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

class CollaborativeWorkspaceScreen extends ConsumerStatefulWidget {
  const CollaborativeWorkspaceScreen({super.key});

  @override
  ConsumerState<CollaborativeWorkspaceScreen> createState() =>
      _CollaborativeWorkspaceScreenState();
}

class _CollaborativeWorkspaceScreenState
    extends ConsumerState<CollaborativeWorkspaceScreen> {
  final List<_Workspace> _workspaces = [
    _Workspace(
      id: 1,
      name: '工作项目',
      description: '团队日常工作记录',
      memberCount: 5,
      recordCount: 128,
      color: Colors.blue,
    ),
    _Workspace(
      id: 2,
      name: '个人生活',
      description: '私人记录',
      memberCount: 1,
      recordCount: 45,
      color: Colors.green,
    ),
  ];

  final List<_Member> _members = [
    _Member(id: 1, name: '张三', avatar: 'Z', role: '管理员'),
    _Member(id: 2, name: '李四', avatar: 'L', role: '成员'),
    _Member(id: 3, name: '王五', avatar: 'W', role: '成员'),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.collaborativeWorkspace),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateWorkspaceDialog,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(isWideScreen ? 24 : 16),
        children: [
          // Quick actions
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.share,
                  title: AppLocalizations.of(context)!.shareRecord,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.group_add,
                  title: AppLocalizations.of(context)!.inviteMember,
                  onTap: () => _showInviteDialog(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Workspaces
          Text(
            AppLocalizations.of(context)!.workspaces,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...(_workspaces.map((workspace) => _buildWorkspaceCard(workspace))),
          const SizedBox(height: 24),

          // Members
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.teamMembers,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton.icon(
                onPressed: _showMembersList,
                icon: const Icon(Icons.people, size: 18),
                label: Text(AppLocalizations.of(context)!.viewAll),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _members
                .map((member) => Chip(
                      avatar: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Text(member.avatar),
                      ),
                      label: Text(member.name),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),

          // Shared records
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.recentShared,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(AppLocalizations.of(context)!.viewAll),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.folder_shared),
                  title: Text('项目周报'),
                  subtitle: Text('张三 • 2小时前'),
                  trailing: Icon(Icons.chevron_right),
                ),
                const ListTile(
                  leading: Icon(Icons.folder_shared),
                  title: Text('会议纪要'),
                  subtitle: Text('李四 • 昨天'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceCard(_Workspace workspace) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openWorkspace(workspace),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: workspace.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.workspaces,
                  color: workspace.color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workspace.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      workspace.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${workspace.memberCount} ${AppLocalizations.of(context)!.members} • ${workspace.recordCount} ${AppLocalizations.of(context)!.records}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateWorkspaceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.createWorkspace),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: AppLocalizations.of(ctx)!.workspaceName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 2,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(ctx)!.description,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.create),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.inviteMember),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: AppLocalizations.of(ctx)!.email,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: AppLocalizations.of(ctx)!.role,
                border: const OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'member', child: Text('成员')),
                DropdownMenuItem(value: 'admin', child: Text('管理员')),
              ],
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.invite),
          ),
        ],
      ),
    );
  }

  void _showMembersList() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView.builder(
        itemCount: _members.length,
        itemBuilder: (context, index) {
          final member = _members[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(member.avatar),
            ),
            title: Text(member.name),
            subtitle: Text(member.role),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {},
            ),
          );
        },
      ),
    );
  }

  void _openWorkspace(_Workspace workspace) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('打开工作空间: ${workspace.name}')),
    );
  }
}

class _Workspace {
  final int id;
  final String name;
  final String description;
  final int memberCount;
  final int recordCount;
  final Color color;

  _Workspace({
    required this.id,
    required this.name,
    required this.description,
    required this.memberCount,
    required this.recordCount,
    required this.color,
  });
}

class _Member {
  final int id;
  final String name;
  final String avatar;
  final String role;

  _Member({
    required this.id,
    required this.name,
    required this.avatar,
    required this.role,
  });
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}