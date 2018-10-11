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

	"github.com/shopspring/decimal"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

var count = 1

const pooruuid = "poor"

// SimpleChaincode example simple Chaincode implementation
type SimpleChaincode struct {
}

//Init 初始化数据 0
func (t *SimpleChaincode) Init(stub shim.ChaincodeStubInterface) pb.Response {
	err := stub.PutState(pooruuid, []byte("0"))
	if err != nil {
		return shim.Error(err.Error())
	}
	fmt.Println("init success")
	return shim.Success(nil)
}

//Invoke 交易
func (t *SimpleChaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	function, args := stub.GetFunctionAndParameters()
	if function == "invoke" {
		return t.allToken(stub, args)
	} else if function == "query" {
		return t.query(stub, args)
	}

	return shim.Error("不正确的方法名，应该是:query、donate")
}

//总的token
func (t *SimpleChaincode) allToken(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	fmt.Println("====================", time.Now().String(), "===============================")
	var (
		err      error
		money    decimal.Decimal
		currentT decimal.Decimal
		//addr  string
	)

	if len(args) != 1 {
		return shim.Error("参数的个数不正确，应该的是1个")
	}

	money, err = decimal.NewFromString(args[0])
	if err != nil {
		return shim.Error("校验参数第二位出错，应该是个浮点型")
	}
	fmt.Println("alltokencc invoke 格式化args[0]:=", money)
	current, err := stub.GetState(pooruuid)
	if err != nil {
		return shim.Error("获取当前的token值失败")
	}
	fmt.Println("alltokencc invoke GetState :=", current)

	//currentT, err = strconv.ParseFloat(string(current), 32)
	currentT, err = decimal.NewFromString(string(current))
	if err != nil {
		return shim.Error("转化当前已有的token失败")
	}
	//相加 计算当前的总钱数  //go 没有decimal 类型
	fmt.Println("alltokencc invoke 转化GetState:=", currentT)
	resultT := currentT.Add(money).String()
	fmt.Println("alltokencc invoke currentT + money:=", resultT)

	// Write the state back to the ledger
	err = stub.PutState(pooruuid, []byte(resultT))
	if err != nil {
		return shim.Error(err.Error())
	}

	fmt.Println("========================alltokencc invoke success================================")
	return shim.Success(nil)
}

//查询所有的token
func (t *SimpleChaincode) query(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	// Write the state back to the ledger
	arr, err := stub.GetState(pooruuid)
	if err != nil {
		return shim.Error(err.Error())
	}

	jsonResp := "{\"Name\":\"" + pooruuid + "\",\"Amount\":\"" + string(arr) + "\"}"
	// Get the state from the ledger
	fmt.Printf("Query Response:%s\n", jsonResp)

	return shim.Success(arr)
}

func main() {
	err := shim.Start(new(SimpleChaincode))
	if err != nil {
		fmt.Printf("启动智能合约出错: %s", err)
	}
}
