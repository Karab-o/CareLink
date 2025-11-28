const EmergencyAlert = require('../models/EmergencyAlert');
const EmergencyContact = require('../models/EmergencyContact');
const NotificationService = require('../services/notificationService');

class AlertsController {
  // Send emergency alert
  static async sendAlert(req, res) {
    try {
      const {
        alertType,
        message,
        latitude,
        longitude,
        address,
        locationAccuracy,
        contactPolice,
      } = req.body;

      // Get active emergency contacts
      const contacts = await EmergencyContact.findActiveByUserId(req.user.id);
      
      if (contacts.length === 0) {
        return res.status(400).json({
          error: 'No Emergency Contacts',
          message: 'You must have at least one active emergency contact to send alerts',
        });
      }

      // Create alert record
      const alertData = {
        user_id: req.user.id,
        alert_type: alertType,
        message: message || null,
        latitude: latitude || null,
        longitude: longitude || null,
        address: address || null,
        location_accuracy: locationAccuracy || null,
        status: 'pending',
        contacts_notified: contacts.map(c => c.id),
        police_contacted: contactPolice ? 1 : 0,
        metadata: {
          user_agent: req.get('User-Agent'),
          ip_address: req.ip,
          timestamp: new Date().toISOString(),
        },
      };

      const alert = new EmergencyAlert(alertData);
      await alert.save();

      // Send notifications asynchronously
      NotificationService.sendEmergencyNotifications(alert, contacts, req.user)
        .then(() => {
          console.log(`✅ Notifications sent for alert ${alert.id}`);
        })
        .catch((error) => {
          console.error(`❌ Failed to send notifications for alert ${alert.id}:`, error);
        });

      // Update alert status to sent
      await alert.updateStatus('sent');

      res.status(201).json({
        message: 'Emergency alert sent successfully',
        alert: {
          id: alert.id,
          alertType: alert.alert_type,
          status: alert.status,
          contactsNotified: alert.contacts_notified.length,
          createdAt: alert.created_at,
        },
      });
    } catch (error) {
      console.error('Send alert error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Failed to send emergency alert',
      });
    }
  }

  // Get user's alert history
  static async getAlertHistory(req, res) {
    try {
      const { limit = 50, offset = 0 } = req.query;
      
      const alerts = await EmergencyAlert.findByUserId(
        req.user.id,
        parseInt(limit)
      );

      // Get contact names for each alert
      const alertsWithContactNames = await Promise.all(
        alerts.map(async (alert) => {
          if (alert.contacts_notified && alert.contacts_notified.length > 0) {
            const contactNames = [];
            for (const contactId of alert.contacts_notified) {
              const contact = await EmergencyContact.findById(contactId);
              if (contact) {
                contactNames.push(contact.name);
              }
            }
            return {
              ...alert,
              contactNames,
            };
          }
          return alert;
        })
      );

      res.json({
        message: 'Alert history retrieved successfully',
        alerts: alertsWithContactNames,
        count: alertsWithContactNames.length,
      });
    } catch (error) {
      console.error('Get alert history error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Failed to retrieve alert history',
      });
    }
  }

  // Get specific alert details
  static async getAlert(req, res) {
    try {
      const { alertId } = req.params;

      const alert = await EmergencyAlert.findById(alertId);
      if (!alert) {
        return res.status(404).json({
          error: 'Alert Not Found',
          message: 'Emergency alert not found',
        });
      }

      if (alert.user_id !== req.user.id) {
        return res.status(403).json({
          error: 'Access Denied',
          message: 'You can only view your own alerts',
        });
      }

      // Get contact details
      let contactDetails = [];
      if (alert.contacts_notified && alert.contacts_notified.length > 0) {
        contactDetails = await Promise.all(
          alert.contacts_notified.map(async (contactId) => {
            const contact = await EmergencyContact.findById(contactId);
            return contact ? {
              id: contact.id,
              name: contact.name,
              phoneNumber: contact.phone_number,
              relationship: contact.relationship,
            } : null;
          })
        );
        contactDetails = contactDetails.filter(contact => contact !== null);
      }

      res.json({
        message: 'Alert details retrieved successfully',
        alert: {
          ...alert,
          contactDetails,
        },
      });
    } catch (error) {
      console.error('Get alert error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Failed to retrieve alert details',
      });
    }
  }

  // Update alert status (acknowledge, resolve, etc.)
  static async updateAlertStatus(req, res) {
    try {
      const { alertId } = req.params;
      const { status, notes } = req.body;

      const alert = await EmergencyAlert.findById(alertId);
      if (!alert) {
        return res.status(404).json({
          error: 'Alert Not Found',
          message: 'Emergency alert not found',
        });
      }

      if (alert.user_id !== req.user.id) {
        return res.status(403).json({
          error: 'Access Denied',
          message: 'You can only update your own alerts',
        });
      }

      const validStatuses = ['pending', 'sent', 'delivered', 'acknowledged', 'resolved', 'failed'];
      if (!validStatuses.includes(status)) {
        return res.status(400).json({
          error: 'Invalid Status',
          message: 'Please provide a valid alert status',
        });
      }

      const additionalData = {};
      if (notes) {
        additionalData.metadata = {
          ...alert.metadata,
          notes,
          statusUpdatedBy: req.user.id,
          statusUpdatedAt: new Date().toISOString(),
        };
      }

      await alert.updateStatus(status, additionalData);

      res.json({
        message: 'Alert status updated successfully',
        alert: {
          id: alert.id,
          status: alert.status,
          acknowledgedAt: alert.acknowledged_at,
          resolvedAt: alert.resolved_at,
        },
      });
    } catch (error) {
      console.error('Update alert status error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Failed to update alert status',
      });
    }
  }

  // Get alert statistics
  static async getAlertStats(req, res) {
    try {
      const stats = await EmergencyAlert.getStatsByUserId(req.user.id);

      res.json({
        message: 'Alert statistics retrieved successfully',
        stats: {
          total: stats.total || 0,
          sent: stats.sent || 0,
          delivered: stats.delivered || 0,
          acknowledged: stats.acknowledged || 0,
          resolved: stats.resolved || 0,
          failed: stats.failed || 0,
        },
      });
    } catch (error) {
      console.error('Get alert stats error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Failed to retrieve alert statistics',
      });
    }
  }

  // Test emergency system
  static async testSystem(req, res) {
    try {
      const contacts = await EmergencyContact.findActiveByUserId(req.user.id);
      
      if (contacts.length === 0) {
        return res.status(400).json({
          error: 'No Emergency Contacts',
          message: 'You must have at least one active emergency contact to test the system',
        });
      }

      // Create test alert
      const testAlert = new EmergencyAlert({
        user_id: req.user.id,
        alert_type: 'general',
        message: 'This is a test of your emergency alert system. No action required.',
        status: 'sent',
        contacts_notified: [contacts[0].id], // Only test with first contact
        metadata: {
          isTest: true,
          testTimestamp: new Date().toISOString(),
        },
      });

      await testAlert.save();

      // Send test notification to first contact only
      try {
        await NotificationService.sendTestNotification(testAlert, contacts[0], req.user);
        console.log(`✅ Test notification sent to ${contacts[0].name}`);
      } catch (notificationError) {
        console.error('❌ Test notification failed:', notificationError);
      }

      res.json({
        message: 'Emergency system test completed',
        testAlert: {
          id: testAlert.id,
          contactTested: contacts[0].name,
          timestamp: testAlert.created_at,
        },
      });
    } catch (error) {
      console.error('Test system error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Failed to test emergency system',
      });
    }
  }
}

module.exports = AlertsController;