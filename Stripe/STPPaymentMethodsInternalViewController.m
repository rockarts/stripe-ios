//
//  STPPaymentMethodsInternalViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 6/9/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodsInternalViewController.h"

#import "NSArray+Stripe_BoundSafe.h"
#import "STPAddCardViewController+Private.h"
#import "STPColorUtils.h"
#import "STPCoreTableViewController+Private.h"
#import "STPCustomerContext.h"
#import "STPCustomerContext+Private.h"
#import "STPImageLibrary.h"
#import "STPImageLibrary+Private.h"
#import "STPLocalizationUtils.h"
#import "STPPaymentMethodTableViewCell.h"
#import "STPSourceProtocol.h"
#import "UINavigationController+Stripe_Completion.h"
#import "UITableViewCell+Stripe_Borders.h"
#import "UIViewController+Stripe_NavigationItemProxy.h"

static NSString *const STPPaymentMethodCellReuseIdentifier = @"STPPaymentMethodCellReuseIdentifier";
static NSInteger STPPaymentMethodCardListSection = 0;
static NSInteger STPPaymentMethodAddCardSection = 1;

@interface STPPaymentMethodsInternalViewController () <UITableViewDataSource, UITableViewDelegate, STPAddCardViewControllerDelegate>

@property (nonatomic) STPPaymentConfiguration *configuration;
@property (nonatomic) STPCustomerContext *customerContext;
@property (nonatomic) STPUserInformation *prefilledInformation;
@property (nonatomic) STPAddress *shippingAddress;
@property (nonatomic) NSArray<id<STPPaymentMethod>> *paymentMethods;
@property (nonatomic) id<STPPaymentMethod> selectedPaymentMethod;
@property (nonatomic, weak) id<STPPaymentMethodsInternalViewControllerDelegate> delegate;

@property (nonatomic) UIImageView *cardImageView;

@end

@implementation STPPaymentMethodsInternalViewController

- (instancetype)initWithConfiguration:(STPPaymentConfiguration *)configuration
                      customerContext:(STPCustomerContext *)customerContext
                                theme:(STPTheme *)theme
                 prefilledInformation:(STPUserInformation *)prefilledInformation
                      shippingAddress:(STPAddress *)shippingAddress
                   paymentMethodTuple:(STPPaymentMethodTuple *)tuple
                             delegate:(id<STPPaymentMethodsInternalViewControllerDelegate>)delegate {
    self = [super initWithTheme:theme];
    if (self) {
        _configuration = configuration;
        _customerContext = customerContext;
        _prefilledInformation = prefilledInformation;
        _shippingAddress = shippingAddress;
        _paymentMethods = tuple.paymentMethods;
        _selectedPaymentMethod = tuple.selectedPaymentMethod;
        _delegate = delegate;

        self.title = STPLocalizedString(@"Payment Method", @"Title for Payment Method screen");
    }
    return self;
}

- (void)createAndSetupViews {
    [super createAndSetupViews];

    // Table view
    [self.tableView registerClass:[STPPaymentMethodTableViewCell class] forCellReuseIdentifier:STPPaymentMethodCellReuseIdentifier];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    // Table header view
    UIImageView *cardImageView = [[UIImageView alloc] initWithImage:[STPImageLibrary largeCardFrontImage]];
    cardImageView.contentMode = UIViewContentModeCenter;
    cardImageView.frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, cardImageView.bounds.size.height + (57.0 * 2.0));
    cardImageView.image = [STPImageLibrary largeCardFrontImage];
    cardImageView.tintColor = self.theme.accentColor;
    self.cardImageView = cardImageView;

    self.tableView.tableHeaderView = cardImageView;

    // Table view editing state
    [self setTableEditing:NO animated:NO];
}

- (void)setTableEditing:(BOOL)isEditing animated:(BOOL)animated {
    UIBarButtonItem *barButtonItem;

    if (!isEditing) {
        barButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(handleEditButtonTapped:)];
    }
    else {
        barButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(handleDoneButtonTapped:)];
    }

    [self.stp_navigationItemProxy setRightBarButtonItem:barButtonItem animated:animated];

    [self.tableView setEditing:isEditing animated:animated];
}

- (void)updateWithPaymentMethodTuple:(STPPaymentMethodTuple *)tuple {
    if ([self.paymentMethods isEqualToArray:tuple.paymentMethods] &&
        [self.selectedPaymentMethod isEqual:tuple.selectedPaymentMethod]) {
        return;
    }

    self.paymentMethods = tuple.paymentMethods;
    self.selectedPaymentMethod = tuple.selectedPaymentMethod;

    NSMutableIndexSet *sections = [NSMutableIndexSet indexSetWithIndex:STPPaymentMethodCardListSection];
    [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Button Handlers

- (void)handleBackOrCancelTapped:(__unused id)sender {
    [self.delegate internalViewControllerDidCancel];
}

- (void)handleEditButtonTapped:(__unused id)sender {
    [self setTableEditing:YES animated:YES];
}

- (void)handleDoneButtonTapped:(__unused id)sender {
    [self setTableEditing:NO animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == STPPaymentMethodCardListSection) {
        return self.paymentMethods.count;
    }

    if (section == STPPaymentMethodAddCardSection) {
        return 1;
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    STPPaymentMethodTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:STPPaymentMethodCellReuseIdentifier forIndexPath:indexPath];

    if (indexPath.section == STPPaymentMethodCardListSection) {
        id<STPPaymentMethod> paymentMethod = [self.paymentMethods stp_boundSafeObjectAtIndex:indexPath.row];
        BOOL selected = [paymentMethod isEqual:self.selectedPaymentMethod];

        [cell configureWithPaymentMethod:paymentMethod selected:selected theme:self.theme];
    } else {
        [cell configureForNewCardRowWithTheme:self.theme];
    }

    return cell;
}

- (BOOL)tableView:(__unused UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == STPPaymentMethodCardListSection) {
        id<STPPaymentMethod> paymentMethod = [self.paymentMethods stp_boundSafeObjectAtIndex:indexPath.row];

        if ([paymentMethod conformsToProtocol:@protocol(STPSourceProtocol)]) {
            // Can be deleted from customer
            return YES;
        }
    }

    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == STPPaymentMethodCardListSection && editingStyle == UITableViewCellEditingStyleDelete) {
        if (indexPath.row < (NSInteger)self.paymentMethods.count) {
            id<STPPaymentMethod> paymentMethodToDelete = [self.paymentMethods objectAtIndex:indexPath.row];

            if ([paymentMethodToDelete conformsToProtocol:@protocol(STPSourceProtocol)]) {
                id<STPSourceProtocol> source = (id<STPSourceProtocol>)paymentMethodToDelete;

                // Kickoff request to delete source from customer
                [self.customerContext detachSourceFromCustomer:source completion:nil];

                // Optimistically remove payment method from data source
                NSMutableArray *paymentMethods = [self.paymentMethods mutableCopy];
                [paymentMethods removeObjectAtIndex:indexPath.row];
                self.paymentMethods = paymentMethods;

                // Perform deletion animation
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            else {
                // Showed the user a delete option when we shouldn't have
                [tableView reloadData];
            }
        } else {
            // Data source and table view out of sync for some reason
            [tableView reloadData];
        }
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == STPPaymentMethodCardListSection) {
        id<STPPaymentMethod> paymentMethod = [self.paymentMethods stp_boundSafeObjectAtIndex:indexPath.row];
        self.selectedPaymentMethod = paymentMethod;

        [tableView reloadSections:[NSIndexSet indexSetWithIndex:STPPaymentMethodCardListSection] withRowAnimation:UITableViewRowAnimationFade];

        [self.delegate internalViewControllerDidSelectPaymentMethod:paymentMethod];
    } else if (indexPath.section == STPPaymentMethodAddCardSection) {
        STPAddCardViewController *paymentCardViewController = [[STPAddCardViewController alloc] initWithConfiguration:self.configuration theme:self.theme];
        paymentCardViewController.delegate = self;
        paymentCardViewController.prefilledInformation = self.prefilledInformation;
        paymentCardViewController.shippingAddress = self.shippingAddress;

        [self.navigationController pushViewController:paymentCardViewController animated:YES];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isTopRow = (indexPath.row == 0);
    BOOL isBottomRow = ([self tableView:tableView numberOfRowsInSection:indexPath.section] - 1 == indexPath.row);

    [cell stp_setBorderColor:self.theme.tertiaryBackgroundColor];
    [cell stp_setTopBorderHidden:!isTopRow];
    [cell stp_setBottomBorderHidden:!isBottomRow];
    [cell stp_setFakeSeparatorColor:self.theme.quaternaryBackgroundColor];
    [cell stp_setFakeSeparatorLeftInset:15.0];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if ([self tableView:tableView numberOfRowsInSection:section] == 0) {
        return 0.01;
    }

    return 27.0;
}

- (CGFloat)tableView:(__unused UITableView *)tableView heightForHeaderInSection:(__unused NSInteger)section {
    return 0.01;
}

- (UITableViewCellEditingStyle)tableView:(__unused UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == STPPaymentMethodCardListSection) {
        return UITableViewCellEditingStyleDelete;
    }

    return UITableViewCellEditingStyleNone;
}

#pragma mark - STPAddCardViewControllerDelegate

- (void)addCardViewControllerDidCancel:(__unused STPAddCardViewController *)addCardViewController {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)addCardViewController:(__unused STPAddCardViewController *)addCardViewController didCreateToken:(STPToken *)token completion:(STPErrorBlock)completion {
    [self.delegate internalViewControllerDidCreateToken:token completion:completion];
}

@end
