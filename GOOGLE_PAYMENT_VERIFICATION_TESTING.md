# Testing Google Payment Verification

This guide explains how to test the Google Play payment verification system in the Shortzz application.

## Setting Up Test Environment

### 1. Create a Test Service Account

For testing purposes, you can create a separate service account with limited permissions:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project for testing or use your development project
3. Enable the Android Publisher API
4. Create a service account with minimal permissions
5. Download the JSON key file

### 2. Configure Test Environment

1. Place the test service account JSON in `storage/credentials/google-service-account-test.json`
2. Update your `.env.testing` file:
   ```
   GOOGLE_SERVICE_ACCOUNT_KEY=storage/credentials/google-service-account-test.json
   GOOGLE_PACKAGE_NAME=com.shortzz.app.test
   ```

## Testing Methods

### Method 1: Using Google Play Billing Library Test Mode

The Google Play Billing Library provides a test mode that allows you to simulate purchases without actual payment:

1. In your Flutter app, use the test mode:
   ```dart
   // Enable test mode
   final bool isTestMode = true;
   
   // Create purchase client with test mode
   final purchaseClient = InAppPurchase.instance;
   ```

2. Make test purchases and send the receipt data to your backend

### Method 2: Mock Verification in Development Environment

For local development, you can mock the verification process:

```php
// Add this to WalletController.php
private function verifyGooglePayment($receipt_data, $amount)
{
    // For testing/development environments, bypass actual verification
    if (app()->environment('local', 'testing')) {
        Log::info("Test environment - mocking Google payment verification");
        
        // Parse receipt data
        $receipt = json_decode($receipt_data, true);
        
        // Basic validation
        if (empty($receipt['packageName']) || empty($receipt['productId']) || empty($receipt['purchaseToken'])) {
            Log::warning("Mock verification failed - invalid receipt format");
            return false;
        }
        
        // Mock successful verification
        return true;
    }
    
    // Production verification code
    try {
        $client = new \Google_Client();
        $client->setAuthConfig(config('services.google.service_account_key'));
        $client->addScope('https://www.googleapis.com/auth/androidpublisher');

        $service = new \Google_Service_AndroidPublisher($client);
        
        $receipt = json_decode($receipt_data, true);
        $packageName = $receipt['packageName'];
        $productId = $receipt['productId'];
        $token = $receipt['purchaseToken'];

        $purchase = $service->purchases_products->get($packageName, $productId, $token);
        
        return $purchase->purchaseState === 0; // 0 = purchased
    } catch (Exception $e) {
        Log::error("Google payment verification failed: " . $e->getMessage());
        return false;
    }
}
```

### Method 3: Unit Testing with Mocks

Create unit tests that mock the Google API responses:

```php
// In your test file
public function testVerifyGooglePayment()
{
    // Mock Google_Service_AndroidPublisher
    $purchaseMock = $this->createMock(\Google_Service_AndroidPublisher_ProductPurchase::class);
    $purchaseMock->purchaseState = 0; // 0 = purchased
    
    $productsMock = $this->createMock(\Google_Service_AndroidPublisher_Resource_PurchasesProducts::class);
    $productsMock->method('get')->willReturn($purchaseMock);
    
    $serviceMock = $this->createMock(\Google_Service_AndroidPublisher::class);
    $serviceMock->purchases_products = $productsMock;
    
    // Create a partial mock of WalletController
    $controller = $this->getMockBuilder(WalletController::class)
        ->setMethods(['createGoogleService'])
        ->getMock();
    
    $controller->method('createGoogleService')->willReturn($serviceMock);
    
    // Test the method
    $receipt_data = json_encode([
        'packageName' => 'com.shortzz.app',
        'productId' => 'coin_pack_100',
        'purchaseToken' => 'mock_token_123'
    ]);
    
    $result = $controller->verifyGooglePayment($receipt_data, 0.99);
    $this->assertTrue($result);
}
```

## Creating Test Receipt Data

For testing, you can create mock receipt data:

```php
// Generate test receipt data
$receipt_data = json_encode([
    'packageName' => 'com.shortzz.app',
    'productId' => 'coin_pack_100',
    'purchaseToken' => 'test_token_' . time(),
    'orderId' => 'GPA.1234-5678-9012-34567',
    'purchaseTime' => time() * 1000 // Milliseconds
]);
```

## Testing with cURL

You can test your API endpoint directly with cURL:

```bash
curl -X POST http://localhost:8000/api/Wallet/purchaseCoin \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "coin": 100,
    "amount": 0.99,
    "payment_method": "in_app_purchase",
    "transaction_reference": "test_transaction_'$(date +%s)'",
    "platform": "android",
    "receipt_data": "{\"packageName\":\"com.shortzz.app\",\"productId\":\"coin_pack_100\",\"purchaseToken\":\"test_token_'$(date +%s)'\",\"orderId\":\"GPA.1234-5678-9012-34567\",\"purchaseTime\":'$(date +%s)000'}",
    "purchase_timestamp": "'$(date -Iseconds)'"
  }'
```

## Testing Negative Cases

Always test failure scenarios:

1. **Invalid Receipt Format**:
   ```json
   {
     "receipt_data": "{\"invalid\": \"format\"}",
     "platform": "android"
   }
   ```

2. **Missing Required Fields**:
   ```json
   {
     "receipt_data": "{\"packageName\":\"com.shortzz.app\"}",
     "platform": "android"
   }
   ```

3. **Zero Amount**:
   ```json
   {
     "amount": 0.00,
     "receipt_data": "...",
     "platform": "android"
   }
   ```

## Integration with Flutter App for Testing

For testing in your Flutter app:

```dart
Future<void> testGooglePaymentVerification() async {
  // Mock purchase data
  final purchaseData = {
    'packageName': 'com.shortzz.app',
    'productId': 'coin_pack_100',
    'purchaseToken': 'test_token_${DateTime.now().millisecondsSinceEpoch}',
    'orderId': 'GPA.1234-5678-9012-34567',
    'purchaseTime': DateTime.now().millisecondsSinceEpoch
  };
  
  try {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/api/Wallet/purchaseCoin'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode({
        'coin': 100,
        'amount': 0.99,
        'payment_method': 'in_app_purchase',
        'transaction_reference': purchaseData['orderId'],
        'platform': 'android',
        'receipt_data': jsonEncode(purchaseData),
        'purchase_timestamp': DateTime.now().toIso8601String()
      })
    );
    
    print('Response: ${response.body}');
    // Handle response
  } catch (e) {
    print('Error: $e');
  }
}
```

## Monitoring and Debugging

For monitoring and debugging payment verification:

1. Enable detailed logging:
   ```php
   Log::debug("Google payment verification", [
       'receipt' => $receipt,
       'purchase_state' => $purchase->purchaseState ?? null
   ]);
   ```

2. Check Laravel logs:
   ```bash
   tail -f storage/logs/laravel.log | grep "payment verification"
   ```

## Conclusion

Testing payment verification thoroughly is crucial to ensure your app's financial integrity. By using these testing methods, you can verify that your implementation works correctly without making actual purchases. 