const express = require('express');
const router = express.Router();
const tuitionController = require('../controllers/tuitionController');
const { requireAuth } = require('../controllers/authControllerV2');

// All tuition routes are secured with requireAuth (only registered phone/email users)
router.use(requireAuth);

// 1. Students Roster & Management
router.get('/students', tuitionController.getStudents);
router.post('/students', tuitionController.addStudent);
router.delete('/students/:studentId', tuitionController.removeStudent);
router.post('/students/:studentId/password', tuitionController.setStudentPassword);

// 2. Attendance (Manual Section)
router.get('/attendance', tuitionController.getAttendance);
router.post('/attendance', tuitionController.markAttendance);
router.get('/attendance/my', tuitionController.getMyAttendance);

// 3. Notes / Study Materials (Manual Section)
router.get('/notes', tuitionController.getNotes);
router.post('/notes', tuitionController.addNote);
router.delete('/notes/:noteId', tuitionController.deleteNote);

// 4. Fees Management (Manual Section)
router.get('/fees', tuitionController.getFees);
router.post('/fees/pay', tuitionController.payFee);
router.get('/fees/my', tuitionController.getMyFees);

// 5. Tests & Marks (Live Proctoring Engine)
router.get('/tests', tuitionController.getTests);
router.post('/tests', tuitionController.addTest);
router.delete('/tests/:testId', tuitionController.deleteTest);
router.post('/tests/:testId/submit', tuitionController.submitLiveTest);
router.get('/proctoring-logs', tuitionController.getProctoringLogs);

// 6. Notices & Announcements (Manual Section)
router.get('/notices', tuitionController.getNotices);
router.post('/notices', tuitionController.addNotice);
router.delete('/notices/:noticeId', tuitionController.deleteNotice);

// 7. Registration Requests (Admin Only)
router.get('/registration-requests', tuitionController.getRegistrationRequests);
router.post('/registration-requests/:studentId/approve', tuitionController.approveStudent);
router.post('/registration-requests/:studentId/reject', tuitionController.rejectStudent);

// 8. Batches & Timetable Management
router.get('/batches', tuitionController.getBatches);
router.post('/batches', tuitionController.addBatch);
router.put('/batches/:batchId', tuitionController.updateBatch);
router.delete('/batches/:batchId', tuitionController.deleteBatch);

// 9. Admin Passkey (Faculty Security Key)
router.get('/admin/passkey', tuitionController.getAdminPasskey);
router.post('/admin/passkey', tuitionController.updateAdminPasskey);

module.exports = router;
