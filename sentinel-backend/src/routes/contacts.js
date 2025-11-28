const express = require('express');
const ContactsController = require('../controllers/contactsController');
const { authenticateToken } = require('../middleware/auth');
const { validateEmergencyContact } = require('../middleware/validation');
const { param } = require('express-validator');

const router = express.Router();

// All routes require authentication
router.use(authenticateToken);

// Get all contacts
router.get('/', ContactsController.getContacts);

// Get active contacts only
router.get('/active', ContactsController.getActiveContacts);

// Get contact statistics
router.get('/stats', ContactsController.getContactStats);

// Add new contact
router.post('/', validateEmergencyContact, ContactsController.addContact);

// Update contact
router.put('/:contactId', [
  param('contactId').isUUID().withMessage('Invalid contact ID'),
  validateEmergencyContact,
], ContactsController.updateContact);

// Delete contact
router.delete('/:contactId', [
  param('contactId').isUUID().withMessage('Invalid contact ID'),
], ContactsController.deleteContact);

module.exports = router;