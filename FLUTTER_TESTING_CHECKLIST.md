# Flutter Testing Checklist

## 🧪 **Quick Verification Steps**

### **1. Build & Run Tests**
```bash
# Clean and rebuild the project
flutter clean
flutter pub get
flutter build apk --debug  # For Android testing
flutter build ios --debug  # For iOS testing
```

### **2. Payment Flow Testing**

#### **✅ Success Scenario**
1. Open the app and navigate to wallet
2. Tap "Buy Coins" 
3. Select a coin package
4. Complete the in-app purchase
5. **Expected**: Coins added to wallet, success message shown
6. **Verify**: Receipt data is sent to backend

#### **✅ Error Handling**
1. Attempt 6+ rapid purchases
2. **Expected**: Rate limit error message
3. **Verify**: "Too many purchase attempts" message

#### **✅ Network Error**
1. Turn off internet during purchase
2. **Expected**: "Network error" message
3. **Verify**: Graceful failure handling

### **3. Code Verification**

#### **✅ API Service Method**
Check `bubbly/lib/api/api_service.dart` line ~1168:
```dart
Future<RestResponse> purchaseCoin(int coin, {
  String? transactionReference, 
  double? amount, 
  String? paymentMethod,
  String? receiptData,           // ✅ NEW
  String? purchaseTimestamp,     // ✅ NEW
  String? coinPackId            // ✅ NEW
}) async
```

#### **✅ Receipt Data Generation**
Check `bubbly/lib/view/wallet/dialog_coins_plan.dart` line ~180:
```dart
// Android receipt data
receiptData = json.encode({
  'packageName': 'com.livetok.app',  // ✅ Correct package
  'productId': element.productID,
  'purchaseToken': element.purchaseID,
  // ... other fields
});
```

#### **✅ Error Handling**
Check `bubbly/lib/modal/rest/rest_response.dart`:
```dart
bool get isRateLimited => _errorCode == 'RATE_LIMIT_EXCEEDED';  // ✅ NEW
bool get isBlocked => _errorCode == 'USER_BLOCKED';             // ✅ NEW
bool get isPaymentError => _errorCode?.contains('PAYMENT');     // ✅ NEW
```

### **4. Platform-Specific Tests**

#### **✅ Android (Google Play)**
1. Test with actual Google Play purchase
2. Verify package name: `com.livetok.app`
3. Check receipt format contains `purchaseToken`
4. Verify error handling for invalid receipts

#### **✅ iOS (App Store)**
1. Test with actual App Store purchase
2. Verify receipt data is base64 encoded
3. Check App Store receipt verification
4. Test subscription handling if applicable

### **5. Security Features**

#### **✅ Receipt Verification**
1. Valid purchase → Success
2. Invalid package name → Error
3. Modified receipt data → Error
4. Check backend logs for verification attempts

#### **✅ Timestamp Tracking**
1. Verify `purchaseTimestamp` is sent
2. Check ISO 8601 format: `2025-01-08T10:30:00.000Z`
3. Confirm backend receives timestamp

#### **✅ Platform Detection**
1. Android: `paymentMethod = 'google_play'`
2. iOS: `paymentMethod = 'app_store'`
3. Platform correctly detected and sent

### **6. User Experience**

#### **✅ Success Messages**
- "Purchase completed successfully!" ✅
- Coins added to wallet ✅
- Dialog closes properly ✅

#### **✅ Error Messages**
- Rate limit: "Too many purchase attempts. Please try again later." ✅
- Blocked: "Your account is temporarily blocked. Please contact support." ✅
- Payment: "Payment verification failed. Please try again." ✅
- Network: "Purchase verification failed: Network error" ✅

### **7. Debug Logging**

#### **✅ Check Console Output**
```dart
// Purchase success
log('Purchase Successfully');

// Error scenarios
log('Purchase verification failed: ${value.errorCode} - ${value.message}');
log('Purchase network error: $error');
```

### **8. Backend Integration**

#### **✅ API Calls**
1. Monitor network requests to `/api/wallet/purchase-coin`
2. Verify all required parameters are sent:
   - `coin` ✅
   - `amount` ✅
   - `payment_method` ✅
   - `transaction_reference` ✅
   - `receipt_data` ✅
   - `purchase_timestamp` ✅
   - `platform` ✅

#### **✅ Response Handling**
1. Status 200 → Success path ✅
2. Status 401 → Error handling ✅
3. Error codes → Specific messages ✅

## 🚨 **Common Issues to Watch For**

### **Build Issues**
- Missing `import 'dart:convert';` in `dialog_coins_plan.dart`
- REST response model compilation errors
- Missing optional parameters in API calls

### **Runtime Issues**
- Null safety errors in receipt data generation
- JSON encoding failures
- Network timeout handling

### **Payment Issues**
- Invalid package name in receipt data
- Missing purchaseToken for Android
- Incorrect receipt format for iOS

## ✅ **Final Verification**

- [ ] App builds successfully on Android
- [ ] App builds successfully on iOS
- [ ] Coin purchase works end-to-end
- [ ] Error messages are user-friendly
- [ ] Receipt data is properly formatted
- [ ] Backend receives all required parameters
- [ ] Security features are working
- [ ] No crashes or exceptions

## 🎉 **Success Criteria**

If all items above are checked, the Flutter app is **fully compatible** with the new backend security implementation and ready for production deployment! 