const twilio = require('twilio');
const sgMail = require('@sendgrid/mail');

class NotificationService {
  constructor() {
    // Initialize Twilio (SMS)
    if (process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN) {
      this.twilioClient = twilio(
        process.env.TWILIO_ACCOUNT_SID,
        process.env.TWILIO_AUTH_TOKEN
      );
      console.log('✅ Twilio SMS service initialized');
    } else {
      console.log('⚠️ Twilio credentials not found - SMS disabled');
    }

    // Initialize SendGrid (Email)
    if (process.env.SENDGRID_API_KEY) {
      sgMail.setApiKey(process.env.SENDGRID_API_KEY);
      console.log('✅ SendGrid email service initialized');
    } else {
      console.log('⚠️ SendGrid API key not found - Email disabled');
    }
  }

  // Send emergency notifications to all contacts
  async sendEmergencyNotifications(alert, contacts, user) {
    const results = [];
    
    for (const contact of contacts) {
      try {
        // Send SMS
        const smsResult = await this.sendEmergencySMS(alert, contact, user);
        results.push({ type: 'sms', contact: contact.name, success: smsResult.success });

        // Send Email if contact has email
        if (contact.email) {
          const emailResult = await this.sendEmergencyEmail(alert, contact, user);
          results.push({ type: 'email', contact: contact.name, success: emailResult.success });
        }

        // Small delay between contacts to avoid rate limiting
        await this.delay(1000);
      } catch (error) {
        console.error(`❌ Failed to notify ${contact.name}:`, error);
        results.push({ type: 'error', contact: contact.name, success: false, error: error.message });
      }
    }

    return results;
  }

  // Send emergency SMS
  async sendEmergencySMS(alert, contact, user) {
    if (!this.twilioClient) {
      console.log('📱 SMS service not available - simulating SMS send');
      return { success: true, simulated: true };
    }

    try {
      const message = this.formatEmergencyMessage(alert, user);
      
      const result = await this.twilioClient.messages.create({
        body: message,
        from: process.env.TWILIO_PHONE_NUMBER,
        to: contact.phone_number,
      });

      console.log(`📱 SMS sent to ${contact.name}: ${result.sid}`);
      return { success: true, messageId: result.sid };
    } catch (error) {
      console.error(`❌ SMS failed for ${contact.name}:`, error);
      return { success: false, error: error.message };
    }
  }

  // Send emergency email
  async sendEmergencyEmail(alert, contact, user) {
    if (!process.env.SENDGRID_API_KEY) {
      console.log('📧 Email service not available - simulating email send');
      return { success: true, simulated: true };
    }

    try {
      const emailContent = this.formatEmergencyEmail(alert, user, contact);
      
      const msg = {
        to: contact.email,
        from: process.env.FROM_EMAIL || 'noreply@sentinel-app.com',
        subject: `🚨 EMERGENCY ALERT - ${user.full_name} needs help`,
        text: emailContent.text,
        html: emailContent.html,
      };

      const result = await sgMail.send(msg);
      console.log(`📧 Email sent to ${contact.name}: ${contact.email}`);
      return { success: true, messageId: result[0].headers['x-message-id'] };
    } catch (error) {
      console.error(`❌ Email failed for ${contact.name}:`, error);
      return { success: false, error: error.message };
    }
  }

  // Send test notification
  async sendTestNotification(alert, contact, user) {
    const testMessage = `🧪 TEST ALERT from Sentinel Safety App\n\nThis is a test message from ${user.full_name}.\n\nYour emergency contact system is working correctly. No action required.\n\nSent at: ${new Date().toLocaleString()}`;

    if (this.twilioClient) {
      try {
        await this.twilioClient.messages.create({
          body: testMessage,
          from: process.env.TWILIO_PHONE_NUMBER,
          to: contact.phone_number,
        });
        console.log(`📱 Test SMS sent to ${contact.name}`);
      } catch (error) {
        console.error(`❌ Test SMS failed:`, error);
      }
    } else {
      console.log(`📱 Test SMS simulated for ${contact.name}: ${testMessage}`);
    }

    return { success: true };
  }

  // Format emergency message for SMS
  formatEmergencyMessage(alert, user) {
    const alertTypes = {
      general: 'GENERAL EMERGENCY',
      medical: 'MEDICAL EMERGENCY',
      violence: 'VIOLENCE/ASSAULT',
      harassment: 'HARASSMENT',
      stalking: 'STALKING',
      accident: 'ACCIDENT',
      fire: 'FIRE EMERGENCY',
      natural_disaster: 'NATURAL DISASTER',
    };

    let message = `🚨 EMERGENCY ALERT 🚨\n\n`;
    message += `${alertTypes[alert.alert_type] || 'EMERGENCY'}\n\n`;
    message += `From: ${user.full_name}\n`;
    
    if (user.phone_number) {
      message += `Phone: ${user.phone_number}\n`;
    }
    
    if (alert.message) {
      message += `Message: ${alert.message}\n`;
    }
    
    if (alert.latitude && alert.longitude) {
      message += `\nLocation:\n`;
      message += `${alert.latitude}, ${alert.longitude}\n`;
      message += `Maps: https://maps.google.com/?q=${alert.latitude},${alert.longitude}\n`;
      
      if (alert.address) {
        message += `Address: ${alert.address}\n`;
      }
    }
    
    message += `\nTime: ${new Date(alert.created_at).toLocaleString()}\n`;
    message += `\nThis is an automated emergency alert from Sentinel Safety App. Please respond immediately.`;
    
    return message;
  }

  // Format emergency email
  formatEmergencyEmail(alert, user, contact) {
    const alertTypes = {
      general: 'General Emergency',
      medical: 'Medical Emergency',
      violence: 'Violence/Assault',
      harassment: 'Harassment',
      stalking: 'Stalking',
      accident: 'Accident',
      fire: 'Fire Emergency',
      natural_disaster: 'Natural Disaster',
    };

    const alertType = alertTypes[alert.alert_type] || 'Emergency';
    
    // Plain text version
    const textContent = this.formatEmergencyMessage(alert, user);
    
    // HTML version
    const htmlContent = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Emergency Alert</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
          .container { max-width: 600px; margin: 0 auto; background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
          .header { background-color: #E53E3E; color: white; padding: 20px; text-align: center; }
          .content { padding: 30px; }
          .alert-type { background-color: #FED7D7; color: #C53030; padding: 10px; border-radius: 5px; margin: 20px 0; font-weight: bold; text-align: center; }
          .info-row { margin: 15px 0; padding: 10px; background-color: #f8f9fa; border-left: 4px solid #E53E3E; }
          .location-box { background-color: #E6FFFA; border: 1px solid #38A169; border-radius: 5px; padding: 15px; margin: 20px 0; }
          .footer { background-color: #f8f9fa; padding: 20px; text-align: center; font-size: 12px; color: #666; }
          .button { display: inline-block; background-color: #E53E3E; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; margin: 10px 5px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🚨 EMERGENCY ALERT</h1>
            <p>Immediate attention required</p>
          </div>
          
          <div class="content">
            <div class="alert-type">${alertType.toUpperCase()}</div>
            
            <div class="info-row">
              <strong>From:</strong> ${user.full_name}
            </div>
            
            ${user.phone_number ? `
            <div class="info-row">
              <strong>Phone:</strong> <a href="tel:${user.phone_number}">${user.phone_number}</a>
            </div>
            ` : ''}
            
            ${alert.message ? `
            <div class="info-row">
              <strong>Message:</strong> ${alert.message}
            </div>
            ` : ''}
            
            <div class="info-row">
              <strong>Time:</strong> ${new Date(alert.created_at).toLocaleString()}
            </div>
            
            ${alert.latitude && alert.longitude ? `
            <div class="location-box">
              <h3>📍 Location Information</h3>
              <p><strong>Coordinates:</strong> ${alert.latitude}, ${alert.longitude}</p>
              ${alert.address ? `<p><strong>Address:</strong> ${alert.address}</p>` : ''}
              <p>
                <a href="https://maps.google.com/?q=${alert.latitude},${alert.longitude}" class="button">
                  View on Google Maps
                </a>
              </p>
            </div>
            ` : ''}
            
            <div style="text-align: center; margin: 30px 0;">
              ${user.phone_number ? `<a href="tel:${user.phone_number}" class="button">Call ${user.full_name}</a>` : ''}
              <a href="tel:911" class="button">Call Emergency Services</a>
            </div>
          </div>
          
          <div class="footer">
            <p>This is an automated emergency alert from Sentinel Safety App.</p>
            <p>Please respond immediately or contact emergency services if needed.</p>
          </div>
        </div>
      </body>
      </html>
    `;

    return {
      text: textContent,
      html: htmlContent,
    };
  }

  // Utility function for delays
  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

// Export singleton instance
module.exports = new NotificationService();