const { v4: uuidv4 } = require('uuid');
const { runQuery, getQuery, allQuery } = require('../config/database');

class EmergencyAlert {
  constructor(data) {
    this.id = data.id || uuidv4();
    this.user_id = data.user_id;
    this.alert_type = data.alert_type;
    this.message = data.message;
    this.latitude = data.latitude;
    this.longitude = data.longitude;
    this.address = data.address;
    this.location_accuracy = data.location_accuracy;
    this.status = data.status || 'pending';
    this.contacts_notified = data.contacts_notified;
    this.police_contacted = data.police_contacted || 0;
    this.acknowledged_at = data.acknowledged_at;
    this.resolved_at = data.resolved_at;
    this.metadata = data.metadata;
    this.created_at = data.created_at;
    this.updated_at = data.updated_at;
  }

  // Save new alert
  async save() {
    const sql = `
      INSERT INTO emergency_alerts (
        id, user_id, alert_type, message, latitude, longitude,
        address, location_accuracy, status, contacts_notified,
        police_contacted, metadata
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;

    const params = [
      this.id,
      this.user_id,
      this.alert_type,
      this.message,
      this.latitude,
      this.longitude,
      this.address,
      this.location_accuracy,
      this.status,
      JSON.stringify(this.contacts_notified),
      this.police_contacted,
      JSON.stringify(this.metadata)
    ];

    await runQuery(sql, params);
    return this;
  }

  // Find alerts by user ID
  static async findByUserId(userId, limit = 50) {
    const sql = `
      SELECT * FROM emergency_alerts 
      WHERE user_id = ? 
      ORDER BY created_at DESC 
      LIMIT ?
    `;
    const rows = await allQuery(sql, [userId, limit]);
    return rows.map(row => {
      const alert = new EmergencyAlert(row);
      // Parse JSON fields
      if (alert.contacts_notified) {
        alert.contacts_notified = JSON.parse(alert.contacts_notified);
      }
      if (alert.metadata) {
        alert.metadata = JSON.parse(alert.metadata);
      }
      return alert;
    });
  }

  // Find alert by ID
  static async findById(id) {
    const sql = 'SELECT * FROM emergency_alerts WHERE id = ?';
    const row = await getQuery(sql, [id]);
    if (row) {
      const alert = new EmergencyAlert(row);
      if (alert.contacts_notified) {
        alert.contacts_notified = JSON.parse(alert.contacts_notified);
      }
      if (alert.metadata) {
        alert.metadata = JSON.parse(alert.metadata);
      }
      return alert;
    }
    return null;
  }

  // Update alert status
  async updateStatus(status, additionalData = {}) {
    const updateData = { status, ...additionalData };
    
    if (status === 'acknowledged') {
      updateData.acknowledged_at = new Date().toISOString();
    } else if (status === 'resolved') {
      updateData.resolved_at = new Date().toISOString();
    }

    const fields = [];
    const values = [];

    Object.keys(updateData).forEach(key => {
      if (updateData[key] !== undefined && key !== 'id') {
        fields.push(`${key} = ?`);
        values.push(updateData[key]);
      }
    });

    fields.push('updated_at = CURRENT_TIMESTAMP');
    values.push(this.id);

    const sql = `UPDATE emergency_alerts SET ${fields.join(', ')} WHERE id = ?`;
    await runQuery(sql, values);

    // Refresh alert data
    const updated = await EmergencyAlert.findById(this.id);
    Object.assign(this, updated);
    return this;
  }

  // Get alert statistics for user
  static async getStatsByUserId(userId) {
    const sql = `
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN status = 'sent' THEN 1 ELSE 0 END) as sent,
        SUM(CASE WHEN status = 'delivered' THEN 1 ELSE 0 END) as delivered,
        SUM(CASE WHEN status = 'acknowledged' THEN 1 ELSE 0 END) as acknowledged,
        SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed,
        SUM(CASE WHEN status = 'resolved' THEN 1 ELSE 0 END) as resolved
      FROM emergency_alerts 
      WHERE user_id = ?
    `;
    return await getQuery(sql, [userId]);
  }
}

module.exports = EmergencyAlert;