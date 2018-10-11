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
	"encoding/json"
	"fmt"
	"os"
	"strconv"
	"time"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

var (
	count       = 1
	itemClose   = false //该项目是否关闭
	alltokencc  = "alltokencc"
	usertokencc = "userlovetokencc"
)

const (
	stateuuid = "itemState"
)

// SimpleChaincode example simple Chaincode implementation
type SimpleChaincode struct {
}

type userInfo struct {
	Address string `json:"adress"` //用户地址
	Money   string `json:"money"`  //用户捐赠的钱数
}

//Init 初始化数据
func (t *SimpleChaincode) Init(stub shim.ChaincodeStubInterface) pb.Response {
	//默认值是0
	// err := stub.PutState("donate1", []byte("0"))
	// if err != nil {
	// 	return shim.Error(err.Error())
	// }

	fmt.Println("userdonate inint success")
	return shim.Success(nil)
}

//Invoke 交易
func (t *SimpleChaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	function, args := stub.GetFunctionAndParameters()

	if function == "donate" {
		return t.donate(stub, args)
	} else if function == "setState" {
		return t.setState(stub, args)
	} else if function == "query" {
		return t.query(stub, args)
	}
	fmt.Println("userdonate invoke:=", function)
	return shim.Error("不正确的方法名，应该是:query、donate、setState")
}

func getTokenCC() {
	if str := os.Getenv("CC_USERTOKENCC"); str != "" {
		usertokencc = str
	} else {
		fmt.Println("使用默认的usertokencc:=", usertokencc)
	}
	if str := os.Getenv("CC_ALLTOKENCC"); str != "" {
		alltokencc = str
	} else {
		fmt.Println("使用默认的alltokencc:=", alltokencc)
	}
}

//捐赠 args ： useraddress  value
func (t *SimpleChaincode) donate(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var (
		uuid string // Entities
		err  error
		//money string
	)

	getTokenCC()

	fmt.Println("userdonate donate:args=", args)

	//判断项目是不是终止
	if itemClose {
		fmt.Println("该项目已经终止。您可以选择别的项目进行捐赠")
		return shim.Error("该项目已经终止。您可以选择别的项目进行捐赠")
	}
	if len(args) != 2 {
		return shim.Error("参数的个数不正确，应该的是2个")
	}

	_, err = strconv.ParseFloat(args[1], 32)
	if err != nil {
		return shim.Error("校验用户捐赠值出错")
	}

	uuid = "donate" + strconv.Itoa(count)
	fmt.Println("userdonate donate:uuid=", uuid)
	u := userInfo{
		Address: args[0],
		Money:   args[1],
	}
	j, err := json.Marshal(u)

	if err != nil {
		return shim.Error("序列化用户捐赠信息出错")
	}
	// Write the state back to the ledger
	fmt.Println("start putsate =====uuid:", uuid, "--info:", string(j))
	err = stub.PutState(uuid, j)
	if err != nil {
		fmt.Println("putsate err:=====")
		return shim.Error(err.Error())
	}
	count++
	fmt.Println("putsate success:=====")
	//调用返给用户token的chaincode 还有基金会总token的chaincode
	result := invokeChaincode(stub, args)
	if result.Status >= 300 || result.Status < 200 {
		return result
	}

	return shim.Success(nil)
}

// query callback representing the query of a chaincode
func (t *SimpleChaincode) query(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var (
		start, end, key string // Entities
		first, last     int
		err             error
	)
	if len(args) != 2 {
		return shim.Error("参数的个数不正确，应该的是2个")
	}

	start = args[0]
	end = args[1]
	if first, err = strconv.Atoi(start); err != nil {
		return shim.Error("校验参数第一位出错，应该是个整数")
	}
	if last, err = strconv.Atoi(end); err != nil {
		return shim.Error("校验参数第二位出错，应该是个整数")
	}

	if first > last {
		return shim.Error("参数的第二位应该大于第一位")
	}

	uarr := []userInfo{}
	var u userInfo

	for i := first; i < last; i++ {
		key = "donate" + strconv.Itoa(i)

		// Get the state from the ledger
		resultbytes, err := stub.GetState(key)
		if err != nil {
			jsonResp := "{\"查询出错：" + key + "\"}"
			return shim.Error(jsonResp)
		}
		json.Unmarshal(resultbytes, &u)

		uarr = append(uarr, u)
	}
	result, err := json.Marshal(uarr)
	if err != nil {
		return shim.Error("格式化查询结果出错")
	}
	// Get the state from the ledger

	return shim.Success(result)
}

// func getRange(stub shim.ChaincodeStubInterface, start, end string) []byte {
// 	arr, err := stub.GetStateByRange(start, end)
// 	if err != nil {

// 	}
// 	for arr.HasNext() {
// 		kv, _ := arr.Next()
// 		kv.GetValue()
// 	}

// }

//设置项目的状态：项目开始，审核、进行中 、终止 args:state isclose
func (t *SimpleChaincode) setState(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var (
		err   error
		value int
		b     bool
	)

	if len(args) != 2 {
		return shim.Error("参数的个数不正确，应该的是2个")
	}

	value, err = strconv.Atoi(args[0])
	if err != nil {
		return shim.Error("校验参数出错，应该是个整数")
	}

	res, err := stub.GetState(stateuuid)
	if err != nil {
		return shim.Error("查询状态出错")
	}
	r, e := strconv.Atoi(string(res))
	if e != nil {
		return shim.Error("查询状态出错")
	}

	if value < r {
		return shim.Error("新设置的值必须大于以前的值")
	}

	b, err = strconv.ParseBool(args[1])
	if err != nil {
		return shim.Error("解析项目是否关闭失败")
	}

	itemClose = b

	// Write the state back to the ledger
	err = stub.PutState(stateuuid, []byte(args[0]))
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(nil)
}

var index = 0

//invokeUserChaincode 调用返给用户token  a,100
func invokeChaincode(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	fmt.Println("====================", time.Now().String(), "===============================")
	fmt.Println("第次:", index, "==执行调用chaincode :args:=", args)

	var (
		funcName      = "invoke"
		allTokenArgs  = make([][]byte, 2)
		userTokenArgs = make([][]byte, len(args)+1)
		//userTokenArgs [][]byte
		channelID = stub.GetChannelID()
	)

	userTokenArgs[0] = []byte(funcName)
	// userTokenArgs[1] = []byte(args[0])
	// userTokenArgs[2] = []byte(args[1])
	for index := 1; index <= len(args); index++ {
		userTokenArgs[index] = []byte(args[index-1])
	}
	// userTokenArgs = append(userTokenArgs, []byte(funcName))
	// for _, str := range args {
	// 	userTokenArgs = append(userTokenArgs, []byte(str))
	// }

	//调用用户的返现token chaincode
	fmt.Println("执行调用chaincode ,name：=", usertokencc, "args:=", string(userTokenArgs[0]), string(userTokenArgs[1]), string(userTokenArgs[2]), "channelid", channelID)
	userresult := stub.InvokeChaincode(usertokencc, userTokenArgs, channelID)
	fmt.Println("执行结果：", userresult)

	allTokenArgs[0] = []byte(funcName)
	allTokenArgs[1] = []byte(args[1])
	//调用基金会的总的token chaincode
	fmt.Println("执行调用chaincode ,name：=", alltokencc, "args:=", allTokenArgs, "channelid", channelID)
	allresult := stub.InvokeChaincode(alltokencc, allTokenArgs, channelID)
	fmt.Println("=========================================================")

	if userresult.Status >= 300 || userresult.Status < 200 {
		userresult.Message = "调用存储所有token的chaincode 错误：" + userresult.Message
		return userresult
	}

	if allresult.Status >= 300 || allresult.Status < 200 {
		allresult.Message = "调用存储所有token的chaincode 错误：" + allresult.Message
		return allresult
	}

	return shim.Success(nil)

}

func main() {
	err := shim.Start(new(SimpleChaincode))
	if err != nil {
		fmt.Printf("启动用户捐赠智能合约出错: %s", err)
	}
}
