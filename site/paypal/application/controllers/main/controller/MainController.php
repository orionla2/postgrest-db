<?php
/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 * Description of MainController
 *
 * @author orionla2
 */


namespace Orion\controllers\main\controller;

use Silex\Api\ControllerProviderInterface;
use Silex\Application;
use Symfony\Component\HttpFoundation\Request;
//use Symfony\Component\HttpFoundation\Response;
//use PayPal\Api as PP;

use PayPal\Api\Address;
use PayPal\Api\BillingInfo;
use PayPal\Api\Cost;
use PayPal\Api\Currency;
use PayPal\Api\Invoice;
use PayPal\Api\InvoiceAddress;
use PayPal\Api\InvoiceItem;
use PayPal\Api\MerchantInfo;
use PayPal\Api\PaymentTerm;
use PayPal\Api\Phone;
use PayPal\Api\ShippingInfo;

use PayPal\Validation\ArgumentValidator;

class MainController implements ControllerProviderInterface {
    //put your code here
    public function connect (Application $app) {
        $controller = $app['controllers_factory'];
        $controller->get('/',[$this,'getMain'])->bind('get-main');
        $controller->get('/createInvoice',[$this,'getCreateInvoice'])->bind('get-createInvoice');
        $controller->post('/',[$this,'postMain'])->bind('post-main');
        $controller->get('/{id}',[$this,'getMainId'])->bind('postId-main');
        return $controller;
    }


    public function getCreateInvoice (Application $app, Request $request) {
        
        require __DIR__ . '/../../../../PayPal/bootstrap.php';
        $invoice = new Invoice();
        // ### Invoice Info
        // Fill in all the information that is
        // required for invoice APIs
        $invoice
            ->setMerchantInfo(new MerchantInfo())
            ->setBillingInfo(array(new BillingInfo()))
            ->setNote("Test Invoice 21 Now, 2016 PST")
            ->setPaymentTerm(new PaymentTerm())
            ->setShippingInfo(new ShippingInfo());
        // ### Merchant Info
        // A resource representing merchant information that can be
        // used to identify merchant
        $invoice->getMerchantInfo()
            ->setEmail("orionla2-facilitator-1@gmail.com")
            ->setFirstName("Andrew")
            ->setLastName("Markov")
            ->setbusinessName("orionla2, LLC")
            ->setPhone(new Phone())
            ->setAddress(new Address());
        $invoice->getMerchantInfo()->getPhone()
            ->setCountryCode("001")
            ->setNationalNumber("5032141716");
        // ### Address Information
        // The address used for creating the invoice
        $invoice->getMerchantInfo()->getAddress()
            ->setLine1("1234 Main St.")
            ->setCity("Nikolaev")
            ->setState("Ni")
            ->setPostalCode("97217")
            ->setCountryCode("US");
        // ### Billing Information
        // Set the email address for each billing
        $billing = $invoice->getBillingInfo();
        $billing[0]
            ->setEmail("orionla2-buyer-1@gmail.com");
        $billing[0]->setBusinessName("Byuer Inc")
            ->setAdditionalInfo("This is the billing Info")
            ->setAddress(new InvoiceAddress());
        $billing[0]->getAddress()
            ->setLine1("1234 Main St.")
            ->setCity("Odessa")
            ->setState("Od")
            ->setPostalCode("97217")
            ->setCountryCode("US");
        // ### Items List
        // You could provide the list of all items for
        // detailed breakdown of invoice
        $items = array();
        $items[0] = new InvoiceItem();
        $items[0]
            ->setName("Test item")
            ->setQuantity(100)
            ->setUnitPrice(new Currency());
        $items[0]->getUnitPrice()
            ->setCurrency("USD")
            ->setValue(5);
        // #### Tax Item
        // You could provide Tax information to each item.
        $tax = new \PayPal\Api\Tax();
        $tax->setPercent(1)->setName("Local Tax on Test items");
        $items[0]->setTax($tax);
        // Second Item
        $items[1] = new InvoiceItem();
        // Lets add some discount to this item.
        $item1discount = new Cost();
        $item1discount->setPercent("3");
        $items[1]
            ->setName("Injection")
            ->setQuantity(5)
            ->setDiscount($item1discount)
            ->setUnitPrice(new Currency());
        $items[1]->getUnitPrice()
            ->setCurrency("USD")
            ->setValue(5);
        // #### Tax Item
        // You could provide Tax information to each item.
        $tax2 = new \PayPal\Api\Tax();
        $tax2->setPercent(3)->setName("Local Tax on Injection");
        $items[1]->setTax($tax2);
        $invoice->setItems($items);
        // #### Final Discount
        // You can add final discount to the invoice as shown below. You could either use "percent" or "value" when providing the discount
        $cost = new Cost();
        $cost->setPercent("2");
        $invoice->setDiscount($cost);
        $invoice->getPaymentTerm()
            ->setTermType("NET_45");
        // ### Shipping Information
        $invoice->getShippingInfo()
            ->setFirstName("Sally")
            ->setLastName("Albatros")
            ->setBusinessName("Not applicable")
            ->setPhone(new Phone())
            ->setAddress(new InvoiceAddress());
        $invoice->getShippingInfo()->getPhone()
            ->setCountryCode("001")
            ->setNationalNumber("5039871234");
        $invoice->getShippingInfo()->getAddress()
            ->setLine1("1234 Main St.")
            ->setCity("Portland")
            ->setState("OR")
            ->setPostalCode("97217")
            ->setCountryCode("US");
        // ### Logo
        // You can set the logo in the invoice by providing the external URL pointing to a logo
        $invoice->setLogoUrl('https://www.paypalobjects.com/webstatic/i/logo/rebrand/ppcom.svg');
        // For Sample Purposes Only.
        $request = clone $invoice;
        try {
            // ### Create Invoice
            // Create an invoice by calling the invoice->create() method
            // with a valid ApiContext (See bootstrap.php for more on `ApiContext`)
            $invoice->create($apiContext);
            $invoice->send($apiContext);
        } catch (Exception $ex) {
            // NOTE: PLEASE DO NOT USE RESULTPRINTER CLASS IN YOUR ORIGINAL CODE. FOR SAMPLE ONLY
            //ResultPrinter::printError("Create Invoice", "Invoice", null, $request, $ex);
            exit(1);
        }
        // NOTE: PLEASE DO NOT USE RESULTPRINTER CLASS IN YOUR ORIGINAL CODE. FOR SAMPLE ONLY
        // ResultPrinter::printResult("Create Invoice", "Invoice", $invoice->getId(), $request, $invoice);
        //return $invoice;
        
        
        return $app['twig']->render('main.html.twig', ['reqObj' => array('invoice' => $invoice, 'invoiceId' => $invoice->getId(), 'validation' => ArgumentValidator::validate($invoice->getId(), "Id"))]);
    }
    public function postMain (Application $app, Request $request) {
        return $app['twig']->render('main.html.twig', ['reqObj' => array('1' => 1, '2' => 2)]);
    }
    public function getMainId (Application $app, Request $request) {
        $token = $this->getToken();
        $sdkConfig = array(
            "mode" => "sandbox"
        );
        var_dump($token->getCredential()->getAccessToken($sdkConfig));
        //return $app['twig']->render('main.html.twig', ['reqObj' => array('request' => $request , 'token' => $token)]);
        return $app['twig']->render('main.html.twig', ['reqObj' => array('token' => 'test')]);
    }
    public function getToken () {
        require __DIR__ . '/../../../../PayPal/bootstrap.php';
        //$oAuth = new OAuthTokenCredential();
        //$token = $oAuth->getToken($config,$this->clientId,$this->clientSecret,$payload);
        //return $token;
        
        $code = "1q2w3e4r"/*$_GET['code']*/;
        return $apiContext;
        /*try {
            $accessToken = OpenIdTokeninfo::createFromAuthorizationCode(array('code' => $code), null, null, $apiContext);
        } catch (PayPalConnectionException $ex) {
            ResultPrinter::printError("Obtained Access Token", "Access Token", null, $_GET['code'], $ex);
            exit(1);
        }*/
    }
}
