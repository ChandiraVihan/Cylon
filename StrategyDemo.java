// Strategy interface (Abstraction)
interface PaymentStrategy {
    void pay(double amount);
}

// Concrete Strategy 1
class CreditCardPayment implements PaymentStrategy {
    private final String cardNumber;
    
    public CreditCardPayment(String cardNumber) {
        this.cardNumber = cardNumber;
    }
    
    @Override
    public void pay(double amount) {
        System.out.println("Paid $" + amount + " using Credit Card ending in " 
                           + cardNumber.substring(cardNumber.length() - 4));
    }
}

// Concrete Strategy 2
class PayPalPayment implements PaymentStrategy {
    private final  String email;
    
    public PayPalPayment(String email) {
        this.email = email;
    }
    
    @Override
    public void pay(double amount) {
        System.out.println("Paid $" + amount + " using PayPal account: " + email);
    }
}

// Context class
class ShoppingCart {
    private PaymentStrategy paymentStrategy;
    
    // Composition: set strategy at runtime
    public void setPaymentStrategy(PaymentStrategy strategy) {
        this.paymentStrategy = strategy;
    }
    
    public void checkout(double amount) {
        if (paymentStrategy == null) {
            throw new IllegalStateException("Payment strategy not set.");
        }
        paymentStrategy.pay(amount); 
    }
}

// Client code
public class StrategyDemo {
    public static void main(String[] args) {
        ShoppingCart cart = new ShoppingCart();
        
        // Pay with credit card
        cart.setPaymentStrategy(new CreditCardPayment("1234567890123456"));
        cart.checkout(150.00);
        
        // Switch to PayPal dynamically
        cart.setPaymentStrategy(new PayPalPayment("user@example.com"));
        cart.checkout(75.50);
    }
}