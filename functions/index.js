const {setGlobalOptions} = require("firebase-functions");
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");

const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");

const logger = require("firebase-functions/logger");

initializeApp();

const db = getFirestore();

setGlobalOptions({
  maxInstances: 10,
});


// ============================================================
// 1. NEW PRICE REPORT
// ============================================================

exports.assignPriceReport = onDocumentCreated(
  "priceReports/{reportId}",
  async (event) => {
    const snapshot = event.data;

    if (!snapshot) {
      logger.error("No price report data found.");
      return;
    }

    const report = snapshot.data();
    const reportId = event.params.reportId;

    // Only process pending reports.
    if (report.status !== "pending") {
      logger.info(
        `Report ${reportId} is not pending. Skipping assignment.`
      );
      return;
    }

    // Get all admins.
    const adminSnapshot = await db
      .collection("users")
      .where("isAdmin", "==", true)
      .get();

    if (adminSnapshot.empty) {
      logger.warn(
        `No admins found for price report ${reportId}.`
      );
      return;
    }

    const admins = [];

    // Check each admin's workload.
    for (const adminDoc of adminSnapshot.docs) {
      const adminData = adminDoc.data();

      // Only assign reports to an admin from the same university.
      if (
        adminData.university &&
        report.university &&
        adminData.university.trim() !==
          report.university.trim()
      ) {
        continue;
      }

      const pendingReportsSnapshot = await db
        .collection("priceReports")
        .where(
          "assignedAdminId",
          "==",
          adminDoc.id
        )
        .where(
          "status",
          "==",
          "pending"
        )
        .get();

      admins.push({
        uid: adminDoc.id,
        pendingCount: pendingReportsSnapshot.size,
      });
    }

    if (admins.length === 0) {
      logger.warn(
        `No suitable admin found for report ${reportId}.`
      );
      return;
    }

    // Sort from least-loaded to most-loaded.
    admins.sort(
      (a, b) => a.pendingCount - b.pendingCount
    );

    // Select the least-loaded admin.
    const selectedAdmin = admins[0];

    const reportRef = db
      .collection("priceReports")
      .doc(reportId);

    const notificationRef = db
      .collection("notifications")
      .doc();

    /*
     * Use a transaction so that if the function is retried,
     * another admin assignment cannot overwrite the first one.
     */
    await db.runTransaction(async (transaction) => {
      const currentReport =
        await transaction.get(reportRef);

      if (!currentReport.exists) {
        throw new Error(
          `Price report ${reportId} no longer exists.`
        );
      }

      const currentData = currentReport.data();

      // Another execution already assigned this report.
      if (currentData.assignedAdminId) {
        logger.info(
          `Report ${reportId} is already assigned.`
        );
        return;
      }

      transaction.update(reportRef, {
        assignedAdminId: selectedAdmin.uid,
      });

      transaction.set(notificationRef, {
        userId: selectedAdmin.uid,
        title: "New Price Report",
        message:
          "A new price report has been assigned to you for review.",
        type: "new_price_report",
        reportId: reportId,
        isRead: false,
        createdAt: new Date(),
      });
    });

    logger.info(
      `Report ${reportId} assigned to admin ` +
      `${selectedAdmin.uid}. ` +
      `Pending reports: ${selectedAdmin.pendingCount}`
    );
  }
);


// ============================================================
// 2. PRICE REPORT STATUS CHANGED
// ============================================================

exports.notifyPriceReportStatus = onDocumentUpdated(
  "priceReports/{reportId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    const reportId = event.params.reportId;

    // Ignore updates that did not change the status.
    if (before.status === after.status) {
      return;
    }

    const status = after.status;
    const reportedBy = after.reportedBy;

    // We only notify students when a report is approved
    // or rejected.
    if (
      status !== "approved" &&
      status !== "rejected"
    ) {
      return;
    }

    if (!reportedBy) {
      logger.warn(
        `Report ${reportId} has no reportedBy UID.`
      );
      return;
    }

    const notificationRef = db
      .collection("notifications")
      .doc();

    const title =
      status === "approved"
        ? "Price Report Approved"
        : "Price Report Rejected";

    const message =
      status === "approved"
        ? "Your price report has been approved."
        : "Your price report has been rejected.";

    await notificationRef.set({
      userId: reportedBy,
      title: title,
      message: message,
      type: "price_report",
      reportId: reportId,
      isRead: false,
      createdAt: new Date(),
    });

    logger.info(
      `Student ${reportedBy} was notified about ` +
      `report ${reportId}: ${status}`
    );
  }
);