/*
Copyright IBM Corp. 2016 All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

		 http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package main

//WARNING - this chaincode's ID is hard-coded in chaincode_example04 to illustrate one way of
//calling chaincode from a chaincode. If this example is modified, chaincode_example04.go has
//to be modified as well with the new ID of chaincode_example02.
//chaincode_example05 show's how chaincode ID can be passed in as a parameter instead of
//hard-coding.

import (
	"fmt"
	"time"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
	"github.com/shopspring/decimal"
)

var count = 1

// SimpleChaincode example simple Chaincode implementation
type SimpleChaincode struct {
}

//Init 初始化数据
func (t *SimpleChaincode) Init(stub shim.ChaincodeStubInterface) pb.Response {

	return shim.Success(nil)
}

//Invoke 交易
func (t *SimpleChaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	function, args := stub.GetFunctionAndParameters()
	if function == "invoke" {
		return t.backToken(stub, args)
	} else if function == "query" {
		return t.query(stub, args)
	}
	fmt.Println("方法名是：", function)
	return shim.Error("不正确的方法名，应该是:query、invoke")
}

//捐赠 args:useraddress value
func (t *SimpleChaincode) backToken(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	fmt.Println("====================", time.Now().String(), "===============================")
	var (
		err error
		//money    float64
		addr     string
		currentT decimal.Decimal
		money    decimal.Decimal
	)
	fmt.Println("backToken args：", args)
	if len(args) != 2 {
		return shim.Error("参数的个数不正确，应该的是2个")
	}

	if args[0] == "" {
		return shim.Error("用户地址不能为空")
	}
	addr = args[0]

	money, err = decimal.NewFromString(args[1])
	if err != nil {
		return shim.Error("校验用户捐赠值出错")
	}
	fmt.Println("backToken strconv.ParseFloat(args[1], 32)money:=", money.String())

	current, err := stub.GetState(addr)
	if err != nil {
		fmt.Println("获取用户token 失败")
		return shim.Error("获取当前的token值失败")
	}

	fmt.Println("获取用户token current:", string(current))
	if string(current) != "" {
		currentT, err = decimal.NewFromString(string(current))
		if err != nil {
			return shim.Error("转化当前已有的token失败")
		}
	}
	res := currentT.Add(money).String()

	fmt.Println("应该存储的token 是：=", res)

	// Write the state back to the ledger
	err = stub.PutState(addr, []byte(res))
	if err != nil {
		return shim.Error(err.Error())
	}
	fmt.Println("====================success===============================")
	return shim.Success(nil)
}

// query callback representing the query of a chaincode
func (t *SimpleChaincode) query(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var (
		addr = args[0]
	)

	if len(args) != 1 {
		return shim.Error("参数的个数不正确，应该的是1个")
	}

	if addr == "" {
		return shim.Error("用户地址不能为空")
	}

	// Write the state back to the ledger
	arr, err := stub.GetState(addr)
	if err != nil {
		return shim.Error(err.Error())
	}
	if arr == nil {
		jsonResp := "{\"Error\":\"Nil amount for " + addr + "\"}"
		return shim.Error(jsonResp)
	}

	jsonResp := "{\"Name\":\"" + addr + "\",\"Amount\":\"" + string(arr) + "\"}"
	fmt.Printf("Query Response:%s\n", jsonResp)
	// Get the state from the ledger

	return shim.Success(arr)
}

func main() {
	err := shim.Start(new(SimpleChaincode))
	if err != nil {
		fmt.Printf("启动智能合约出错: %s", err)
	}
}
