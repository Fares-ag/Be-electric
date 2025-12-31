# QAuto CMMS Mobile App - Training Guide

## 📱 **Mobile App Overview**

The QAuto CMMS Mobile App is a comprehensive maintenance management system designed for technicians and managers to manage work orders, preventive maintenance tasks, and asset tracking on mobile devices.

## 🚀 **Getting Started**

### **1. App Installation**

#### **For Android:**

1. Download the APK file from your IT department
2. Enable "Install from Unknown Sources" in Android settings
3. Install the app by tapping the APK file
4. Grant necessary permissions (Camera, Storage, Location)

#### **For iOS:**

1. Download from the App Store (when available)
2. Or install via TestFlight for beta testing
3. Grant necessary permissions when prompted

### **2. First Login**

1. **Open the app** and you'll see the login screen
2. **Enter your credentials** provided by your IT department:
   - Email: `your.email@company.com`
   - Password: `your_password`
3. **Tap "Login"** to access the app
4. **Grant permissions** for camera, storage, and notifications

## 🏠 **Dashboard Overview**

### **Main Navigation**

- **Dashboard**: Overview of your tasks and statistics
- **Work Orders**: View and manage work orders
- **PM Tasks**: Preventive maintenance tasks
- **Assets**: Asset search and information
- **Profile**: Your account settings

### **Dashboard Cards**

- **Open Work Orders**: Number of assigned work orders
- **Overdue Tasks**: Tasks that need immediate attention
- **PM Due Today**: Preventive maintenance due today
- **Completed This Week**: Your completed tasks

## 📋 **Work Orders**

### **Viewing Work Orders**

1. **Tap "Work Orders"** in the bottom navigation
2. **Filter options**:
   - Status: Open, In Progress, Completed
   - Priority: Low, Medium, High, Critical
   - Sort by: Due Date, Priority, Created Date

### **Creating a Work Request**

1. **Tap the "+" button** on the Work Orders screen
2. **Fill in the form**:
   - **Asset**: Tap to search or scan QR code
   - **Location**: Enter or select from list
   - **Problem Description**: Describe the issue
   - **Priority**: Select appropriate priority
   - **Attach Photo**: Take photo or select from gallery
3. **Tap "Submit Request"**

### **Working on a Work Order**

1. **Tap on a work order** to view details
2. **Tap "Start Work"** to begin
3. **Update progress** as you work
4. **Add notes** about what you're doing
5. **Take photos** of the work in progress
6. **Tap "Complete Work"** when finished

### **Completing a Work Order**

1. **Fill in completion details**:
   - **Corrective Actions Taken**: What you did to fix it
   - **Recommendations**: Suggestions for prevention
   - **Next Maintenance**: When it should be checked again
2. **Add your signature** using the signature pad
3. **Tap "Close Ticket"** to complete

## 🔧 **Preventive Maintenance (PM) Tasks**

### **Viewing PM Tasks**

1. **Tap "PM Tasks"** in the bottom navigation
2. **Tasks are sorted by due date**
3. **Overdue tasks** are highlighted in red
4. **Tap on a task** to view details

### **Completing a PM Task**

1. **Tap on a PM task** to open it
2. **Review the checklist** items
3. **Check off completed items**
4. **Add notes** about any issues found
5. **Take photos** if needed
6. **Add your signature**
7. **Tap "Mark Complete"**

## 📱 **Asset Management**

### **Searching for Assets**

1. **Tap "Assets"** in the bottom navigation
2. **Use the search bar** to find assets by name
3. **Tap on an asset** to view details
4. **View maintenance history** and upcoming tasks

### **QR Code Scanning**

1. **Tap the QR code icon** in asset search
2. **Point camera at QR code**
3. **Asset information** will appear automatically
4. **Tap "Select Asset"** to use it

### **Manual Asset Entry**

1. **Tap "Manual Search"** in asset search
2. **Enter asset name or serial number**
3. **Select from search results**
4. **Tap "Select Asset"** to use it

## ⚙️ **Settings and Configuration**

### **API Configuration (For IT Staff)**

1. **Tap the menu (⋮)** in the top-right corner
2. **Select "API Configuration"**
3. **Enter Q-AUTO API URL**:
   - `https://us-central1-your-project.cloudfunctions.net`
4. **Enter API key** (if required)
5. **Tap "Test Connection"**
6. **Tap "Save Configuration"**
7. **Tap "Sync Assets"** to pull latest data

### **Profile Settings**

1. **Tap "Profile"** in the bottom navigation
2. **View your information**:
   - Name, Email, Role, Department
   - Last login time
   - App version
3. **Change password** if needed
4. **Logout** when finished

## 🔔 **Notifications**

### **Push Notifications**

- **New work orders** assigned to you
- **Overdue tasks** that need attention
- **PM reminders** for upcoming tasks
- **System updates** and announcements

### **Notification Settings**

1. **Go to device Settings**
2. **Find "QAuto CMMS"**
3. **Enable/disable notification types**
4. **Set notification sounds** and vibration

## 📸 **Camera and Photos**

### **Taking Photos**

1. **Tap the camera icon** in forms
2. **Grant camera permission** if prompted
3. **Point camera** at the subject
4. **Tap the capture button**
5. **Review and retake** if needed
6. **Tap "Use Photo"** to attach

### **Photo Guidelines**

- **Good lighting** for clear photos
- **Include relevant details** in the frame
- **Take multiple angles** if helpful
- **Keep photos under 5MB** for faster upload

## ✍️ **Digital Signatures**

### **Adding Your Signature**

1. **Tap the signature pad** when prompted
2. **Sign with your finger** or stylus
3. **Tap "Clear"** to start over
4. **Tap "Done"** when satisfied
5. **Signature is saved** with the work order

### **Signature Tips**

- **Use a stylus** for better precision
- **Sign clearly** and legibly
- **Keep signature consistent** across documents

## 🔄 **Offline Mode**

### **Working Offline**

- **App works without internet** connection
- **Data is saved locally** on your device
- **Syncs automatically** when connection returns
- **No data loss** during offline work

### **Sync Status**

- **Green dot**: Connected and synced
- **Yellow dot**: Connected, sync in progress
- **Red dot**: Offline, will sync when connected

## 🆘 **Troubleshooting**

### **Common Issues**

#### **App Won't Start**

- **Restart the app**
- **Restart your device**
- **Check for app updates**
- **Contact IT support**

#### **Can't Login**

- **Check your credentials**
- **Ensure internet connection**
- **Try "Forgot Password"**
- **Contact IT support**

#### **Photos Won't Upload**

- **Check internet connection**
- **Reduce photo size**
- **Clear app cache**
- **Restart the app**

#### **QR Code Won't Scan**

- **Clean camera lens**
- **Ensure good lighting**
- **Hold steady for 2-3 seconds**
- **Try manual search instead**

#### **Sync Issues**

- **Check internet connection**
- **Go to API Configuration**
- **Test connection**
- **Tap "Sync Assets"**

### **Getting Help**

- **Contact IT Support**: `support@qauto.com`
- **Phone Support**: `+1-555-QAUTO`
- **Check FAQ**: In-app help section
- **Report Bugs**: Use the feedback form

## 📊 **Best Practices**

### **Daily Workflow**

1. **Check dashboard** for new assignments
2. **Review overdue tasks** first
3. **Update work order status** regularly
4. **Take photos** of important work
5. **Complete tasks** with proper documentation
6. **Sync data** before end of day

### **Work Order Best Practices**

- **Start work immediately** when assigned
- **Update progress** throughout the day
- **Take before/after photos**
- **Document all actions taken**
- **Complete with signature**

### **PM Task Best Practices**

- **Follow checklists completely**
- **Note any issues found**
- **Take photos of problems**
- **Update maintenance schedules**
- **Complete on time**

### **Asset Management**

- **Scan QR codes** when possible
- **Verify asset information**
- **Report missing assets**
- **Update asset conditions**

## 🎯 **Performance Tips**

### **Battery Optimization**

- **Close unused apps**
- **Reduce screen brightness**
- **Use Wi-Fi when available**
- **Enable battery saver mode**

### **Data Usage**

- **Use Wi-Fi for large uploads**
- **Compress photos** when possible
- **Sync during off-peak hours**
- **Monitor data usage**

### **Storage Management**

- **Clear old photos** regularly
- **Delete unused apps**
- **Use cloud storage** for backups
- **Keep 1GB free space**

## 📈 **Success Metrics**

### **Key Performance Indicators**

- **Work Order Completion Rate**: Target 95%+
- **PM Task On-Time Rate**: Target 90%+
- **Photo Documentation Rate**: Target 80%+
- **User Satisfaction**: Target 4.5/5 stars

### **Monthly Reviews**

- **Check completion rates**
- **Review user feedback**
- **Identify training needs**
- **Update procedures**

---

## 📞 **Support Contacts**

- **IT Support**: `support@qauto.com`
- **Phone**: `+1-555-QAUTO`
- **Emergency**: `+1-555-EMERGENCY`
- **Website**: `https://support.qauto.com`

## 📚 **Additional Resources**

- **Video Tutorials**: Available in-app
- **User Manual**: Download from support site
- **FAQ**: Check in-app help section
- **Training Videos**: Contact IT for access

---

**Remember**: This app is designed to make your work easier and more efficient. Take time to learn the features, and don't hesitate to ask for help when needed!






















