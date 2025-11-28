const express = require('express');
const AlertsController = require('../controllers/alertsController');
const { authenticateToken } = require('../middleware/auth');
const { validateEmergencyAlert } = require('../middleware/validation');
const { param, body } = require('express-validator');

const router = express.Router();

// All routes require authentication
router.use(authenticateToken);

// Send emergency alert
router.post('/', validateEmergencyAlert, AlertsController.sendAlert);

// Get alert history
router.get('/', AlertsController.getAlertHistory);

// Get alert statistics
router.get('/stats', AlertsController.getAlertStats);

// Test emergency system
router.post('/test', AlertsController.testSystem);

// Get specific alert
router.get('/:alertId', [
  param('alertId').isUUID().withMessage('Invalid alert ID'),
], AlertsController.getAlert);

// Update alert status
router.put('/:alertId/status', [
  param('alertId').isUUID().withMessage('Invalid alert ID'),
  body('status')
    .isIn(['pending', 'sent', 'delivered', 'acknowledged', 'resolved', 'failed'])
    .withMessage('Invalid status'),
  body('notes').optional().isLength({ max: 500 }).withMessage('Notes must be less than 500 characters'),
], AlertsController.updateAlertStatus);

module.exports = router;