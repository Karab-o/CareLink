import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_dimensions.dart';
import '../providers/app_provider.dart';
import '../models/emergency_alert.dart';

/// Screen showing history of all emergency alerts
class AlertsHistoryScreen extends StatefulWidget {
  const AlertsHistoryScreen({super.key});

  @override
  State<AlertsHistoryScreen> createState() => _AlertsHistoryScreenState();
}

class _AlertsHistoryScreenState extends State<AlertsHistoryScreen> {
  AlertType? _selectedFilter;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          final alerts = _getFilteredAlerts(appProvider.emergencyAlerts as List<EmergencyAlertss>);
          
          return Column(
            children: [
              // Search and Filter Bar
              _buildSearchBar(),
              
              // Statistics Banner
              _buildStatisticsBanner(appProvider.emergencyAlerts as List<EmergencyAlertss>),
              
              // Alerts List
              Expanded(
                child: alerts.isEmpty 
                    ? _buildEmptyState() 
                    : _buildAlertsList(alerts, appProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search alerts...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          
          if (_selectedFilter != null) ...[
            const SizedBox(width: AppDimensions.paddingM),
            Chip(
              label: Text(_selectedFilter!.displayName),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() {
                  _selectedFilter = null;
                });
              },
              backgroundColor: AppColors.emergencyRedLight,
              labelStyle: AppTextStyles.caption.copyWith(
                color: AppColors.emergencyRed,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticsBanner(List<EmergencyAlertss> allAlerts) {
    final totalAlerts = allAlerts.length;
    final sentAlerts = allAlerts.where((a) => a.status == AlertStatus.sent || 
                                           a.status == AlertStatus.delivered ||
                                           a.status == AlertStatus.acknowledged).length;
    final failedAlerts = allAlerts.where((a) => a.status == AlertStatus.failed).length;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem('Total', totalAlerts.toString(), AppColors.info),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.mediumGray,
          ),
          Expanded(
            child: _buildStatItem('Sent', sentAlerts.toString(), AppColors.safeGreen),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.mediumGray,
          ),
          Expanded(
            child: _buildStatItem('Failed', failedAlerts.toString(), AppColors.error),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h3.copyWith(color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: AppColors.backgroundGray,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history,
                size: 60,
                color: AppColors.textLight,
              ),
            ),
            
            const SizedBox(height: AppDimensions.paddingL),
            
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != null
                  ? 'No Matching Alerts'
                  : 'No Alert History',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: AppDimensions.paddingM),
            
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != null
                  ? 'Try adjusting your search or filter criteria.'
                  : 'Emergency alerts you send will appear here for your reference.',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsList(List<EmergencyAlertss> alerts, AppProvider appProvider) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        return _buildAlertCard(alerts[index], appProvider);
      },
    );
  }

  Widget _buildAlertCard(EmergencyAlertss alert, AppProvider appProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      child: InkWell(
        onTap: () => _showAlertDetails(alert, appProvider),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Alert Type Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getAlertStatusColor(alert.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    ),
                    child: Icon(
                      _getAlertTypeIcon(alert.type),
                      color: _getAlertStatusColor(alert.status),
                      size: AppDimensions.iconM,
                    ),
                  ),
                  
                  const SizedBox(width: AppDimensions.paddingM),
                  
                  // Alert Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                alert.type.displayName,
                                style: AppTextStyles.h4,
                              ),
                            ),
                            _buildStatusChip(alert.status),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        Text(
                          _formatDateTime(alert.createdAt),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        
                        if (alert.message != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            alert.message!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textLight,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppDimensions.paddingM),
              
              // Alert Details Row
              Row(
                children: [
                  if (alert.location != null) ...[
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Location shared',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingM),
                  ],
                  
                  const Icon(
                    Icons.contacts,
                    size: 16,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${alert.contactIds.length} contacts',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  if (alert.metadata?['isTest'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'TEST',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.info,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(AlertStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _getAlertStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: AppTextStyles.caption.copyWith(
          color: _getAlertStatusColor(status),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Alerts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Types'),
              leading: Radio<AlertType?>(
                value: null,
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ),
            ...AlertType.values.map((type) => ListTile(
              title: Text(type.displayName),
              leading: Radio<AlertType?>(
                value: type,
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value;
                  });
                  Navigator.of(context).pop();
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showAlertDetails(EmergencyAlertss alert, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getAlertTypeIcon(alert.type),
              color: _getAlertStatusColor(alert.status),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(alert.type.displayName),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Status', alert.status.displayName),
              _buildDetailRow('Date & Time', _formatFullDateTime(alert.createdAt)),
              
              if (alert.message != null)
                _buildDetailRow('Message', alert.message!),
              
              if (alert.location != null) ...[
                _buildDetailRow('Location Shared', 'Yes'),
                if (alert.location!.address != null)
                  _buildDetailRow('Address', alert.location!.address!),
                _buildDetailRow(
                  'Coordinates',
                  '${alert.location!.latitude.toStringAsFixed(6)}, ${alert.location!.longitude.toStringAsFixed(6)}',
                ),
              ],
              
              _buildDetailRow('Contacts Notified', '${alert.contactIds.length}'),
              
              if (alert.acknowledgedAt != null)
                _buildDetailRow('Acknowledged', _formatFullDateTime(alert.acknowledgedAt!)),
              
              if (alert.metadata?['isTest'] == true)
                _buildDetailRow('Type', 'Test Alert'),
              
              if (alert.metadata?['error'] != null)
                _buildDetailRow('Error', alert.metadata!['error']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (alert.location != null)
            ElevatedButton(
              onPressed: () {
                // TODO: Open location in maps
                Navigator.of(context).pop();
              },
              child: const Text('View Location'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.label,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  List<EmergencyAlertss> _getFilteredAlerts(List<EmergencyAlertss> alerts) {
    final filtered = alerts.where((alert) {
      // Filter by type
      if (_selectedFilter != null && alert.type != _selectedFilter) {
        return false;
      }
      
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return alert.type.displayName.toLowerCase().contains(query) ||
               (alert.message?.toLowerCase().contains(query) ?? false) ||
               alert.status.displayName.toLowerCase().contains(query);
      }
      
      return true;
    }).toList();
    
    // Sort by creation date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return filtered;
  }

  IconData _getAlertTypeIcon(AlertType type) {
    switch (type) {
      case AlertType.general:
        return Icons.emergency;
      case AlertType.medical:
        return Icons.medical_services;
      case AlertType.violence:
        return Icons.security;
      case AlertType.harassment:
        return Icons.report_problem;
      case AlertType.stalking:
        return Icons.visibility;
      case AlertType.accident:
        return Icons.car_crash;
      case AlertType.fire:
        return Icons.local_fire_department;
      case AlertType.naturalDisaster:
        return Icons.warning;
      case AlertType.safety:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  Color _getAlertStatusColor(AlertStatus status) {
    switch (status) {
      case AlertStatus.pending:
        return AppColors.warningOrange;
      case AlertStatus.sent:
      case AlertStatus.delivered:
        return AppColors.info;
      case AlertStatus.acknowledged:
      case AlertStatus.resolved:
        return AppColors.safeGreen;
      case AlertStatus.failed:
        return AppColors.error;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  String _formatFullDateTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy \'at\' h:mm a').format(dateTime);
  }
}