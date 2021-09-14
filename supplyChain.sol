// SPDX-License-Identifier: SC
pragma solidity >=0.7.0 <0.9.0;

contract SupplyChain{
    
    /*
    * Enums for getting order status
    */
    
    enum OrderStatus{
        PLACED,
        ACKNOWLEDGED,
        SHIPPED,
        DELIVERED,
        CANCELLED,
        TAMPERED,
        LATE,
        SHIPPEDLATE
    }
    
    /*
    struct for general Order
    */
    
    struct Order {
        uint256 orderId;
        uint prodID;
        uint256 quantity;
        address SupplierId;
        address storeId; // client
        uint256 amount;
        OrderStatus status;
        uint createdDate;
        uint deliveryDate;
    }
    
    /*
    struct for Supplier 
    */
    
    // struct Supplier{
    //     address id;
    //     mapping (address => Order) myOrders;
    //     uint ordersCount;
    //     // mapping(uint256 => string) products;
    //     // uint256 trackingId;
    //     // uint256 invoiceNo;
    //     // uint shippingDate;
    // }
    
    /*
    struct for Store/Consumer/Client 
    */
    
    // struct Store{
    //     address id;
    //     string  name;
    //     // mapping(uint256 => string) products;
    // }
    
    
    /*
    struct for Order's list data 
    */
    Order[] public orders;
    
    
    mapping (address => Order[]) myOrders;
    
    mapping (address => uint256) suppliersBalances;
    
    event OrderUpdate(address indexed from,address indexed to);
    
        event orderLateWarning(address indexed from,address indexed to);
    
    /*
    get the overall count for all Orders on BLockchain 
    */
    
    function getAllCount () external view returns(uint)
    {
        return orders.length;
    }
    
    /*
    get the order for specific supplier 
    */
    
    function fetchOrderByID(uint myOrderId) public view returns (Order memory) {
        
        Order memory myOrder;
        
        for (uint i=0; i<orders.length ; i++)
        {
            require (orders[i].orderId==myOrderId,"Not found");
            myOrder = orders[i];
        }
 
        return myOrder;
    }
    
    function fetchAllOrdersSupplier() external view returns (Order[]  memory ordersOf) {
        

        uint ordersLen= orders.length;
         Order[] memory _orders = new Order[](ordersLen);
        
         for (uint i = 0; i < ordersLen; i++) {
             
            require (orders[i].SupplierId==msg.sender,"Not found");
          Order storage _order = myOrders[msg.sender][i];
          _orders[i] = _order;
      }

      return _orders;
        
    }
    
    
    /*
    * Supplier acknowledges the order
    */
    
    function acknowledgeOrder(uint256 _orderId) external returns (bool) {
          
          
          address _store;
          
        for (uint i=0; i<orders.length ; i++)
        {
            require (orders[i].orderId==_orderId,"Not found");
            orders[i].status = OrderStatus.ACKNOWLEDGED;
            orders[i].deliveryDate = block.timestamp + 7 days;
            _store = orders[i].storeId;
        }
        
        emit OrderUpdate(msg.sender,_store);
          
          return true;
          
      }
    
    /*
    * Supplier can ship products
    */
    
    function shipOrder(uint256 _orderId) external returns (bool) {
          
          
          address _store;
          
        for (uint i=0; i<orders.length ; i++)
        {
            require (orders[i].orderId==_orderId,"Not found");
            
            if (block.timestamp <= orders[i].deliveryDate)
            {
                  orders[i].status = OrderStatus.SHIPPED;
                  _store = orders[i].storeId; 
                  emit orderLateWarning(_store,msg.sender);
                  
            }else {
                
                  orders[i].status = OrderStatus.SHIPPEDLATE;
                  _store = orders[i].storeId; 
                  
            }
        }
        
        emit OrderUpdate(msg.sender,_store);
          
          return true;
          
      }
    
    
    /*
    Supplier can check its balance
    */
    
    function checkBalance (address val) public view returns (uint) {
        return suppliersBalances[val];
    }
    
    
    /*
    * Client/Store can place order for products to any supplier by providing its address
    */
    
    function placeOrder (uint prodID,uint256 quantity,address _supplierId,uint256 amount) external returns (uint) {
        
        require (amount>0,"Amount too low.");
        uint orderid = block.timestamp;
        
        Order memory newOrder = Order(orderid,prodID,quantity,_supplierId,msg.sender,amount,OrderStatus.PLACED,block.timestamp,block.timestamp+7 days);
        orders.push(newOrder);
        
        emit OrderUpdate(msg.sender,_supplierId);
        
        // myOrders[_supplierId].push(newOrder);
        
        return orderid;
        
    }
    
    /*
    * getting all orders of client/store
    */
    
    function fetchAllOrdersStore() external view returns (Order[]  memory ordersOf) {
        

        uint ordersLen= orders.length;
         Order[] memory _orders = new Order[](ordersLen);
        
        for (uint i = 0; i < ordersLen; i++) {
             
        require (orders[i].storeId==msg.sender,"Not found");
          Order storage _order = myOrders[msg.sender][i];
          _orders[i] = _order;
      }

      return _orders;
        
    }
    
    /*
    * Verify the order shipment delivered
    */
    
    function verifyShipment (bool val, uint256 _order) external {
        
               
        for (uint i=0; i<orders.length ; i++)
        {
            require (orders[i].orderId==_order,"Not found");
            
            if (val)
            {
                if (orders[i].status == OrderStatus.SHIPPEDLATE)
                {
                    orders[i].status = OrderStatus.LATE; 
                suppliersBalances[orders[i].SupplierId] += orders[i].amount;
                }
                else {
                       orders[i].status = OrderStatus.DELIVERED; 
                
                suppliersBalances[orders[i].SupplierId] += orders[i].amount;
                }
             
                
                        emit OrderUpdate(msg.sender,orders[i].SupplierId);
        
                
            }else{
                orders[i].status = OrderStatus.TAMPERED;  
                emit OrderUpdate(msg.sender,orders[i].SupplierId);
            }

        }
          
        
    }
    
    function trackDelivery (uint256 _id) public view returns (string memory) {
        
        string memory _status;
        
        for (uint i=0; i<orders.length ; i++)
        {
            require (orders[i].orderId==_id,"Not found");
            _status= getStatus(orders[i].status);
        }
          
          return _status;
        
    }
    
    function getStatus(OrderStatus _status) public view returns (string memory)
    {
        if (_status==OrderStatus.PLACED)
        {
            return "Order Placed";
        }else if (_status==OrderStatus.ACKNOWLEDGED)
        {
            return "Order Acknowledged by Supplier";
        }else if (_status==OrderStatus.SHIPPED)
        {
            return "Order Shipped by Supplier";
        }else if (_status==OrderStatus.DELIVERED)
        {
            return "Order Delivered";
        }else if (_status==OrderStatus.LATE)
        {
            return "Order Delivered late by Supplier";
        }else if (_status==OrderStatus.CANCELLED)
        {
            return "Order Cancelled by Supplier";
        }else if (_status==OrderStatus.SHIPPEDLATE)
        {
            return "Order shipped late by Supplier";
        }else if (_status==OrderStatus.TAMPERED)
        {
            return "Shipment tampered. Order not completed";
        }
        
        return "Not found";
        
    }
    
    
}