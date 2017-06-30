# Stripe iOS Objective-C Style Guide

## Ground Rules

### Spacing

- Indent using 4 spaces. No tabs.

- Avoid starting methods with an empty line

- There should not be a need to use multiple consecutive empty lines

- Asterisks should be attached to the variable name `NSString *text` unless it's `NSString * const Text`

### Variable Naming

- Lean towards clarity over compactness

- Avoid single letter variables. Try using `idx` / `jdx` instead of `i` / `j` in for loops.

- Prefer `urlString` over `URLString` (acronym prefix), `baseUrlString` over `baseURLString` (acronym infix), and `stripeId` over `stripeID` (acronym suffix)

### Control Flow

- Place `else if` and `else` on their own lines:

```objc
if (condition) {
    // A
}
else if (condition) {
    // B
}
else {
    // C
}
```

- Always wrap conditional bodies with curly braces

- Use ternary operators sparingly and for simple conditions only:

```objc
type = isCard ? @"card" : @"unknown";

type = dictionary[@"type"] ?: @"default";
```

### Documentation

- Document using this format:

```objc
/// This is a one line description for a simple method
- (void)title;

/**
 This is a multi-line description for a complicated method

 @param

 @see https://...
 */
- (void)title;
```

### Literals

- Use literals for immutable instances of `NSString`, `NSDictionary`, `NSArray`, `NSNumber`:

```objc
NSArray *brands = @[@"visa", @"mastercard", @"discover"];

NSDictionary *parameters = @{
                              @"currency": @"usd",
                              @"amount": @1000,
                            };
```

- Dictionary colons should be attached to the key

- Align multi-line literals using default Xcode indentation

### Constants

- Use static constants whenever appropriate. Names should start with a capital letter:

```objc
static NSString * const HTTPMethodGET = @"GET";

static const CGFloat ButtonHeight = 100.0;
```

- Any public static constants should be prefixed with `STP`:

```objc
static NSString *const STPSDKVersion = @"11.0.0";
```

### Folders

- We use a mostly flat folder structure on disk

- Separate `Stripe` and `StripeTests`

- Separate `PublicHeaders` inside `Stripe/` for Cocoapods compatibility

## Design Patterns

### Imports

- Ordering for imports in headers
  - Import system frameworks
  - Import superclasses and protocols sorted alphabetically
  - Use `@class` for everything else

```objc
#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"
#import "STPBankAccountParams.h"

@class STPAddress, @STPToken;
```

- Ordering for imports in implementations
  - Import system frameworks
  - Import corresponding headers
  - Import everything else sorted alphabetically

```objc
#import <PassKit/PassKit.h>

#import "STPSource.h"
#import "STPSource+Private.h"

#import "NSDictionary+Stripe.h"
#import "STPSourceOwner.h"
#import "STPSourceReceiver.h"
#import "STPSourceRedirect.h"
#import "STPSourceVerification.h"
```

### Interfaces and Protocols

- Stick to Xcode default spacing for interfaces, categories, and protocols

- Always use `NS_ASSUME_NON_NULL_BEGIN` / `NS_ASSUME_NON_NULL_END` in headers

```objc
NS_ASSUME_NON_NULL_BEGIN

@protocol STPSourceProtocol <NSObject>

//

@end

...

@interface STPSource : NSObject<STPAPIResponseDecodable, STPSourceProtocol>

//

@end

...

@interface STPSource () <STPInternalAPIResponseDecodable>

//

@end

NS_ASSUME_NON_NULL_END
```

- Category methods on certain classes should be prefixed with `stp_` to avoid collision:

```
@interface NSDictionary (Stripe)

- (NSDictionary *)stp_jsonDictionary;

@end
```

- Define private properties as class extensions inside the implementation when necessary

- Use a class extension in a `+Private.h` file to access methods internal to the framework

- Something about private access from tests

### Properties

- Properties should be defined using this syntax:

```
@property (<nonatomic / atomic>, <weak / copy / _>, <readonly / readwrite / _>, <nullable / _>) <class> *<name>;

@property (<nonatomic / atomic>, <assign>, <readonly / readwrite / _>) <type> <name>;
```

- Use `copy` for classes with mutable counterparts such as `NSString`, `NSArray`, `NSDictionary`

- Leverage auto property synthesis whenever possible

- Declare `@synthesize` and `@dynamic` on separate lines for shorter diffs

### Init

```objc
- (instancetype)init {
    self = [super init];
    if (self) {
        //
    }
    return self;
}
```

- `[STPCard new]` vs `[[STPCard alloc] init]`

### Methods

```
- (void)setExampleText:(NSString *)text image:(UIImage *)image {

}
```

### Implementation

- In long implementation files, use `#pragma mark -` to group methods

```
#pragma mark - Button Handlers

#pragma mark - UITableViewDataSource

#pragma mark - UITableViewDelegate
```

### Booleans

if (!someObject) {
}

if (someObject == nil) {
}

if (isAwesome)
if (!someNumber.boolValue)
if (someNumber.boolValue == NO)

Not:
if (isAwesome == YES) // Never do this.

???
