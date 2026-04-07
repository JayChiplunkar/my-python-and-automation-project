*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    BuiltIn

Suite Setup    Create Session    order_api    ${BASE_URL}
Suite Teardown    Delete All Sessions

*** Variables ***
${BASE_URL}                     http://localhost:8000
${CREATE_ORDER_ENDPOINT}        /orders
${GET_ORDER_ENDPOINT}           /orders/
${UPDATE_ORDER_ENDPOINT}        /orders/
${DELETE_ORDER_ENDPOINT}        /orders/
${LIST_ORDERS_ENDPOINT}         /orders

# Valid Test Data
${VALID_CUSTOMER_NAME}          John Doe
${VALID_PRODUCT}                Apple Laptop
${VALID_QUANTITY}               5
${VALID_PRICE}                  1200.50

# Update Test Data
${UPDATE_CUSTOMER_NAME}          Jane Smith
${UPDATE_PRODUCT}                Dell Monitor
${UPDATE_QUANTITY}               3
${UPDATE_PRICE}                  350.75

# Invalid Test Data (1 character - less than minimum 2)
${INVALID_CUSTOMER_SINGLE_CHAR}  A
${INVALID_PRODUCT_SINGLE_CHAR}   B
${INVALID_QUANTITY_ZERO}         0
${INVALID_QUANTITY_NEGATIVE}     -5
${INVALID_PRICE_ZERO}            0.0
${INVALID_PRICE_NEGATIVE}        -100.50
${INVALID_ORDER_ID}              507f1f77bcf86cd799439999

# Response Validation Keywords
${STATUS_ORDER_PLACED}           Order Placed
${STATUS_ORDER_UPDATED}          Order Updated


*** Test Cases ***

TC001: Create Order With Valid Data
    [Tags]    CREATE    VALID
    [Documentation]    Create an order with all valid parameters and verify response
    ${order_payload}=    Create Dictionary    customer_name=${VALID_CUSTOMER_NAME}    product=${VALID_PRODUCT}    quantity=${VALID_QUANTITY}    price=${VALID_PRICE}
    ${response}=    POST On Session    order_api    ${CREATE_ORDER_ENDPOINT}    json=${order_payload}
    Should Be Equal As Integers    ${response.status_code}    200
    Dictionary Should Contain Key    ${response.json()}    id
    Dictionary Should Contain Key    ${response.json()}    customer_name
    Dictionary Should Contain Key    ${response.json()}    product
    Dictionary Should Contain Key    ${response.json()}    quantity
    Dictionary Should Contain Key    ${response.json()}    price
    Dictionary Should Contain Key    ${response.json()}    status
    Should Be Equal    ${response.json()}[status]    ${STATUS_ORDER_PLACED}
    Set Suite Variable    ${CREATED_ORDER_ID}    ${response.json()}[id]


TC002: Create Order With Invalid Customer Name (Single Character)
    [Tags]    CREATE    INVALID
    [Documentation]    Create order with single character customer name should fail with 422
    ${order_payload}=    Create Dictionary    customer_name=${INVALID_CUSTOMER_SINGLE_CHAR}    product=${VALID_PRODUCT}    quantity=${VALID_QUANTITY}    price=${VALID_PRICE}
    ${response}=    POST On Session    order_api    ${CREATE_ORDER_ENDPOINT}    json=${order_payload}    expected_status=422
    Should Be Equal As Integers    ${response.status_code}    422


TC003: Create Order With Invalid Product (Single Character)
    [Tags]    CREATE    INVALID
    [Documentation]    Create order with single character product should fail with 422
    ${order_payload}=    Create Dictionary    customer_name=${VALID_CUSTOMER_NAME}    product=${INVALID_PRODUCT_SINGLE_CHAR}    quantity=${VALID_QUANTITY}    price=${VALID_PRICE}
    ${response}=    POST On Session    order_api    ${CREATE_ORDER_ENDPOINT}    json=${order_payload}    expected_status=422
    Should Be Equal As Integers    ${response.status_code}    422


TC004: Create Order With Invalid Quantity (Zero)
    [Tags]    CREATE    INVALID
    [Documentation]    Create order with quantity 0 should fail with 422
    ${order_payload}=    Create Dictionary    customer_name=${VALID_CUSTOMER_NAME}    product=${VALID_PRODUCT}    quantity=${INVALID_QUANTITY_ZERO}    price=${VALID_PRICE}
    ${response}=    POST On Session    order_api    ${CREATE_ORDER_ENDPOINT}    json=${order_payload}    expected_status=422
    Should Be Equal As Integers    ${response.status_code}    422


TC005: Create Order With Invalid Quantity (Negative)
    [Tags]    CREATE    INVALID
    [Documentation]    Create order with negative quantity should fail with 422
    ${order_payload}=    Create Dictionary    customer_name=${VALID_CUSTOMER_NAME}    product=${VALID_PRODUCT}    quantity=${INVALID_QUANTITY_NEGATIVE}    price=${VALID_PRICE}
    ${response}=    POST On Session    order_api    ${CREATE_ORDER_ENDPOINT}    json=${order_payload}    expected_status=422
    Should Be Equal As Integers    ${response.status_code}    422


TC006: Create Order With Invalid Price (Zero)
    [Tags]    CREATE    INVALID
    [Documentation]    Create order with price 0 should fail with 422
    ${order_payload}=    Create Dictionary    customer_name=${VALID_CUSTOMER_NAME}    product=${VALID_PRODUCT}    quantity=${VALID_QUANTITY}    price=${INVALID_PRICE_ZERO}
    ${response}=    POST On Session    order_api    ${CREATE_ORDER_ENDPOINT}    json=${order_payload}    expected_status=422
    Should Be Equal As Integers    ${response.status_code}    422


TC007: Create Order With Invalid Price (Negative)
    [Tags]    CREATE    INVALID
    [Documentation]    Create order with negative price should fail with 422
    ${order_payload}=    Create Dictionary    customer_name=${VALID_CUSTOMER_NAME}    product=${VALID_PRODUCT}    quantity=${VALID_QUANTITY}    price=${INVALID_PRICE_NEGATIVE}
    ${response}=    POST On Session    order_api    ${CREATE_ORDER_ENDPOINT}    json=${order_payload}    expected_status=422
    Should Be Equal As Integers    ${response.status_code}    422


TC008: Get Order By Valid ID
    [Tags]    READ    VALID
    [Documentation]    Retrieve order using valid order ID from TC001
    ${response}=    GET On Session    order_api    ${GET_ORDER_ENDPOINT}${CREATED_ORDER_ID}
    Should Be Equal As Integers    ${response.status_code}    200
    Should Be Equal    ${response.json()}[id]    ${CREATED_ORDER_ID}
    Should Be Equal    ${response.json()}[customer_name]    ${VALID_CUSTOMER_NAME}
    Should Be Equal    ${response.json()}[product]    ${VALID_PRODUCT}


TC009: Get Order By Invalid ID
    [Tags]    READ    INVALID
    [Documentation]    Retrieve order with non-existent ID should return 404
    ${response}=    GET On Session    order_api    ${GET_ORDER_ENDPOINT}${INVALID_ORDER_ID}    expected_status=404
    Should Be Equal As Integers    ${response.status_code}    404


TC010: Update Order With Valid Data
    [Tags]    UPDATE    VALID
    [Documentation]    Update order with all valid parameters
    ${update_payload}=    Create Dictionary    customer_name=${UPDATE_CUSTOMER_NAME}    product=${UPDATE_PRODUCT}    quantity=${UPDATE_QUANTITY}    price=${UPDATE_PRICE}
    ${response}=    PUT On Session    order_api    ${UPDATE_ORDER_ENDPOINT}${CREATED_ORDER_ID}    json=${update_payload}
    Should Be Equal As Integers    ${response.status_code}    200
    Should Be Equal    ${response.json()}[customer_name]    ${UPDATE_CUSTOMER_NAME}
    Should Be Equal    ${response.json()}[product]    ${UPDATE_PRODUCT}
    Should Be Equal    ${response.json()}[status]    ${STATUS_ORDER_UPDATED}


TC011: Update Order With Invalid Customer Name
    [Tags]    UPDATE    INVALID
    [Documentation]    Update order with single character customer name should fail
    ${update_payload}=    Create Dictionary    customer_name=${INVALID_CUSTOMER_SINGLE_CHAR}
    ${response}=    PUT On Session    order_api    ${UPDATE_ORDER_ENDPOINT}${CREATED_ORDER_ID}    json=${update_payload}    expected_status=422
    Should Be Equal As Integers    ${response.status_code}    422


TC012: Update Order With Invalid Product
    [Tags]    UPDATE    INVALID
    [Documentation]    Update order with single character product should fail
    ${update_payload}=    Create Dictionary    product=${INVALID_PRODUCT_SINGLE_CHAR}
    ${response}=    PUT On Session    order_api    ${UPDATE_ORDER_ENDPOINT}${CREATED_ORDER_ID}    json=${update_payload}    expected_status=422
    Should Be Equal As Integers    ${response.status_code}    422


TC013: Update Non-Existent Order
    [Tags]    UPDATE    INVALID
    [Documentation]    Update order with invalid ID should return 404
    ${update_payload}=    Create Dictionary    customer_name=${UPDATE_CUSTOMER_NAME}
    ${response}=    PUT On Session    order_api    ${UPDATE_ORDER_ENDPOINT}${INVALID_ORDER_ID}    json=${update_payload}    expected_status=404
    Should Be Equal As Integers    ${response.status_code}    404


TC014: List All Orders
    [Tags]    READ    VALID
    [Documentation]    Retrieve list of all orders and verify it contains created order
    ${response}=    GET On Session    order_api    ${LIST_ORDERS_ENDPOINT}
    Should Be Equal As Integers    ${response.status_code}    200
    ${orders}=    Set Variable    ${response.json()}
    Should Not Be Empty    ${orders}


TC015: Verify No Duplicate Order IDs In List
    [Tags]    READ    VALID    DATA_INTEGRITY
    [Documentation]    Get all orders and verify no duplicate IDs exist
    ${response}=    GET On Session    order_api    ${LIST_ORDERS_ENDPOINT}
    Should Be Equal As Integers    ${response.status_code}    200
    ${orders}=    Set Variable    ${response.json()}
    ${order_ids}=    Create List
    FOR    ${order}    IN    @{orders}
        Append To List    ${order_ids}    ${order}[id]
    END
    ${unique_ids}=    Get List Without Duplicates    ${order_ids}
    Length Should Be    ${order_ids}    ${unique_ids.__len__()}


TC016: Delete Order By Valid ID
    [Tags]    DELETE    VALID
    [Documentation]    Delete order using the created order ID
    ${response}=    DELETE On Session    order_api    ${DELETE_ORDER_ENDPOINT}${CREATED_ORDER_ID}
    Should Be Equal As Integers    ${response.status_code}    200
    Dictionary Should Contain Key    ${response.json()}    message
    Should Be Equal    ${response.json()}[message]    Order deleted successfully


TC017: Delete Non-Existent Order
    [Tags]    DELETE    INVALID
    [Documentation]    Delete order with invalid ID should return 404
    ${response}=    DELETE On Session    order_api    ${DELETE_ORDER_ENDPOINT}${INVALID_ORDER_ID}    expected_status=404
    Should Be Equal As Integers    ${response.status_code}    404


TC018: Verify Order Is Deleted
    [Tags]    DELETE    VALID    DATA_INTEGRITY
    [Documentation]    Try to fetch deleted order and verify it returns 404
    ${response}=    GET On Session    order_api    ${GET_ORDER_ENDPOINT}${CREATED_ORDER_ID}    expected_status=404
    Should Be Equal As Integers    ${response.status_code}    404


*** Keywords ***

Get List Without Duplicates
    [Arguments]    ${list}
    [Documentation]    Returns the list with duplicates removed
    ${unique_list}=    Create List
    FOR    ${item}    IN    @{list}
        ${contains}=    Run Keyword And Return Status    List Should Contain Value    ${unique_list}    ${item}
        Run Keyword If    not ${contains}    Append To List    ${unique_list}    ${item}
    END
    RETURN    ${unique_list}
