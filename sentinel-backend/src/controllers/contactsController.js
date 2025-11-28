const EmergencyContact = require('../models/EmergencyContact');

class ContactsController {
  // Get all emergency contacts for user
  static async getContacts(req, res) {
    try {
      const contacts = await EmergencyContact.findByUserId(req.user.id);
      
      res.json({
        message: 'Contacts retrieved successfully',
        contacts: contacts,
        count: contacts.length,
      });
    } catch (error) {
      console.error('Get contacts error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Failed to retrieve contacts',
      });
    }
  }

  // Get active emergency contacts for user
  static async getActiveContacts(req, res) {
    try {
      const contacts = await EmergencyContact.findActiveByUserId(req.user.id);
      
      res.json({
        message: 'Active contacts retrieved successfully',
        contacts: contacts,
        count: contacts.length,
      });
    } catch (error) {
      console.error('Get active contacts error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Failed to retrieve active contacts',
      });
    }
  }

  // Add new emergency contact
  static async addContact(req, res) {
    try {
      const { name, phoneNumber, email, relationship, priorityOrder } = req.body;

      // Check if user already has this phone number
      const existingContacts = await EmergencyContact.findByUserId(req.user.id);
      const duplicatePhone = existingContacts.find(contact => contact.phone_number === phoneNumber);
      
      if (duplicatePhone) {
        return res.status(409).json({
          error: 'Duplicate Contact',
          message: 'A contact with this phone number already exists',
        });
      }

      const contactData = {
        user_id: req.user.id,
        name: name.trim(),
        phone_number: phoneNumber,
        email: email ? email.trim() : null,
        relationship,
        priority_order: priorityOrder || 1,
      };

      const contact = new EmergencyContact(contactData);
      await contact.save();

      res.status(201).json({
        message: 'Emergency contact added successfully',
        contact: contact,
      });
    } catch (error) {
      console.error('Add contact error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Failed to add emergency contact',
      });
    }
  }

  // Update emergency contact
  static async updateContact(req, res) {
    try {
      const { contactId } = req.params;
      const { name, phoneNumber, email, relationship, isActive, priorityOrder } = req.body;

      // Find contact and verify ownership
      const contact = await EmergencyContact.findById(contactId);
      if (!contact) {
        return res.status(404).json({
          error: 'Contact Not Found',
          message: 'Emergency contact not found',
        });
      }

      if (contact.user_id !== req.user.id) {
        return res.status(403).json({
          error: 'Access Denied',
          message: 'You can only update your own contacts',
        });
      }

      // Check for duplicate phone number (excluding current contact)
      if (phoneNumber && phoneNumber !== contact.phone_number) {
        const existingContacts = await EmergencyContact.findByUserId(req.user.id);
        const duplicatePhone = existingContacts.find(c => 
          c.phone_number === phoneNumber && c.id !== contactId
        );
        
        if (duplicatePhone) {
          return res.status(409).json({
            error: 'Duplicate Contact',
            message: 'A contact with this phone number already exists',
          });
        }
      }

      const updateData = {};
      if (name !== undefined) updateData.name = name.trim();
      if (phoneNumber !== undefined) updateData.phone_number = phoneNumber;
      if (email !== undefined) updateData.email = email ? email.trim() : null;
      if (relationship !== undefined) updateData.relationship = relationship;
      if (isActive !== undefined) updateData.is_active = isActive ? 1 : 0;
      if (priorityOrder !== undefined) updateData.priority_order = priorityOrder;

      await contact.update(updateData);

      res.json({
        message: 'Emergency contact updated successfully',
        contact: contact,
      });
    } catch (error) {
      console.error('Update contact error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Failed to update emergency contact',
      });
    }
  }

  // Delete emergency contact
  static async deleteContact(req, res) {
    try {
      const { contactId } = req.params;

      // Find contact and verify ownership
      const contact = await EmergencyContact.findById(contactId);
      if (!contact) {
        return res.status(404).json({
          error: 'Contact Not Found',
          message: 'Emergency contact not found',
        });
      }

      if (contact.user_id !== req.user.id) {
        return res.status(403).json({
          error: 'Access Denied',
          message: 'You can only delete your own contacts',
        });
      }

      await contact.delete();

      res.json({
        message: 'Emergency contact deleted successfully',
      });
    } catch (error) {
      console.error('Delete contact error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Failed to delete emergency contact',
      });
    }
  }

  // Get contact statistics
  static async getContactStats(req, res) {
    try {
      const totalContacts = await EmergencyContact.getCountByUserId(req.user.id);
      const allContacts = await EmergencyContact.findByUserId(req.user.id);
      const activeContacts = allContacts.filter(contact => contact.is_active).length;
      
      // Group by relationship
      const relationshipStats = allContacts.reduce((acc, contact) => {
        acc[contact.relationship] = (acc[contact.relationship] || 0) + 1;
        return acc;
      }, {});

      res.json({
        message: 'Contact statistics retrieved successfully',
        stats: {
          total: totalContacts,
          active: activeContacts,
          inactive: totalContacts - activeContacts,
          byRelationship: relationshipStats,
        },
      });
    } catch (error) {
      console.error('Get contact stats error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Failed to retrieve contact statistics',
      });
    }
  }
}

module.exports = ContactsController;