//
//  ViewController.swift
//  hh
//
//  Created by 王建智 on 2019/4/16.
//  Copyright © 2019 王建智. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate,UITableViewDataSource,UITableViewDelegate {
    var bles:[String]=[String]()
    var bl=true
    @IBOutlet var id4: UITextField!
    @IBOutlet var id3: UITextField!
    @IBOutlet var id2: UITextField!
    @IBOutlet var id1: UITextField!
    var connectblename=""
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell=tableView.dequeueReusableCell(withIdentifier:"blecell", for: indexPath)as! blecell
        cell.name.text=bles[indexPath.row]
        cell.controller=self
        cell.canconnect=bl
        return cell
    }
    
    @IBOutlet var tb: UITableView!
    @IBOutlet var toolbar: UIView!
    // 自訂一個錯誤型態
    enum SendDataError: Error {
        case CharacteristicNotFound
    }
    var yt=0
    let C001_CHARACTERISTIC = "8D81"
    
    var centralManager: CBCentralManager!
    // 儲存連上的 peripheral，此變數一定要宣告為全域
    var connectPeripheral: CBPeripheral!
    // 記錄所有的 characteristic
    var charDictionary = [String: CBCharacteristic]()
    
    /* 當 central 端重新執行後，嘗試取回 peripheral */
    func isPaired() -> Bool {
        let user = UserDefaults.standard
        if let uuidString = user.string(forKey: "KEY_PERIPHERAL_UUID") {
            let uuid = UUID(uuidString: uuidString)
            let list = centralManager.retrievePeripherals(withIdentifiers: [uuid!])
            if list.count > 0 {
                connectPeripheral = list.first!
                connectPeripheral.delegate = self
                return true
            }
        }
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let queue = DispatchQueue.global()
        tb.separatorStyle = .none
        centralManager = CBCentralManager(delegate: self, queue: queue)
        mytool().shadow(in: toolbar.layer, he: 5)
    }
    
    /* 1號method */
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // 先判斷藍牙是否開啟，如果不是藍牙4.x ，也會傳回電源未開啟
        guard central.state == .poweredOn else {
            // iOS 會出現對話框提醒使用者
            return
        }
            centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    /* 2號method */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        guard let deviceName = peripheral.name else {
            return
        }
        print("找到藍牙裝置: \(deviceName))")
        if !(bles.contains(deviceName)){bles.append(deviceName)
            DispatchQueue.main.async {
                self.tb.reloadData()
            }
                    }
        guard deviceName.range(of: connectblename) != nil
            else {
                return
        }
        DispatchQueue.main.async {
            self.bles.removeAll()
            self.bles.append("連線至\(deviceName)")
            self.tb.reloadData()
        }
        central.stopScan()
        let user = UserDefaults.standard
        user.set(peripheral.identifier.uuidString, forKey: "KEY_PERIPHERAL_UUID")
        user.synchronize()
        connectPeripheral = peripheral
        connectPeripheral.delegate = self
        centralManager.connect(connectPeripheral, options: nil)
           }
    
    /* 3號method */
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // 清除上一次儲存的 characteristic 資料
        charDictionary = [:]
        // 將觸發 4號method
        peripheral.discoverServices(nil)
    }
    
    /* 4號method */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("ERROR: \(#file, #function)")
            print(error!.localizedDescription)
            return
        }
        
        for service in peripheral.services! {
            // 將觸發 5號method
            connectPeripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    /* 5號method */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("ERROR: \(#file, #function)")
            print(error!.localizedDescription)
            return
        }
        
        for characteristic in service.characteristics! {
            let uuidString = characteristic.uuid.uuidString
            charDictionary[uuidString] = characteristic
            print("找到: \(uuidString)")
            peripheral.discoverDescriptors(for: characteristic)
        }
//        guard charDictionary[C001_CHARACTERISTIC] != nil else{return}
//        connectPeripheral.setNotifyValue(true, for: charDictionary[C001_CHARACTERISTIC]!)
    }
    
    /* 將資料傳送到 peripheral */
    func sendData(_ data: Data, uuidString: String, writeType: CBCharacteristicWriteType)  {
        guard let characteristic = charDictionary[uuidString] else {
mytool().WriteError()
            return
        }
        connectPeripheral.writeValue(
            data,
            for: characteristic,
            type: writeType
        )
    }
    
    /* 將資料傳送到 peripheral 時如果遇到錯誤會呼叫 */
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("寫入資料錯誤: \(error!)")
        }else{
            
            print("--------朽入資料-------")
            print(characteristic.value)
//            }
        }
    }
    
    /* 取得 peripheral 送過來的資料 */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("ERROR: \(#file, #function)")
            print(error!)
            return
        }
        let data = characteristic.value
        //            let string = "> " + String(data: data as Data, encoding: .utf8)!
          print("收到數據ㄦ---------")
        for i in 0...data!.count-1{
            print(String(format:"%02X",data![i]))
        }
    }
    
    /* 訂閱與取消訂閱開關 */
    @IBAction func subscribeValue(_ sender: UISwitch) {
//        connectPeripheral.setNotifyValue(sender.isOn, for: charDictionary[C001_CHARACTERISTIC]!)
    }
    var bo=true
    /* 按下送出按鈕 */
    @IBAction func sendClick(_ sender: Any) {
        print("通知情況\(charDictionary[C001_CHARACTERISTIC])")
        if(id1.text!.count<6||id1.text!.count>8){mytool().info();return}
        if(id2.text!.count<6||id2.text!.count>8){mytool().info();return}
        if(id3.text!.count<6||id3.text!.count>8){mytool().info();return}
        if(id4.text!.count<6||id4.text!.count>8){mytool().info();return}
        var bt:[UInt8]=[0x60,0xA2,0x00,0xFF,0xFF,0xFF,0xFF,0xC2,0x0A]
        var data = Data(bytes: bt)
        bl=false
        bles.append(mytool().DataString(bt, 8))
        tb.reloadData()
        sendData(data, uuidString:"8D81", writeType: .withResponse)
        usleep(200000)
        for i in 0..<4{
            switch i{
            case 0:
                bt=mytool().Setire(0x01, id1.text!)
                break
            case 1:
                bt=mytool().Setire(0x02, id2.text!)
                break
            case 2:
                bt=mytool().Setire(0x03, id3.text!)
                break
            case 3:
                bt=mytool().Setire(0x04, id4.text!)
                break
            default:
                break
            }
            data = Data(bytes: bt)
            sendData(data, uuidString:"8D81", writeType: .withResponse)
            bles.append(mytool().DataString(bt, 8))
            bl=false
            tb.reloadData()
            usleep(200000)
                   }
        bt=[0x60,0xA2,0xFF,0xFF,0xFF,0xFF,0xFF,0x3D,0x0A]
//        bt=[0x53,0xA9,0x01,0xFF,0xFF,0xFF,0xFF,0xFB,0x0A]
        data = Data(bytes: bt)
        let bytes = [UInt8](data)
        print("送出\(bytes)")
        sendData(data, uuidString:"8D81", writeType: .withResponse)
        bl=false
        bles.append(mytool().DataString(bt, 8))
        tb.reloadData()
    }
    
    /* 向 periphral 送出讀資料請求 */
    @IBAction func readDataClick(_ sender: Any) {
        let characteristic = charDictionary[C001_CHARACTERISTIC]!
        connectPeripheral.readValue(for: characteristic)
    }
    
    /* 斷線處理 */
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("連線中斷")
        if isPaired() {

            centralManager.connect(connectPeripheral, options: nil)
//            guard (charDictionary[C001_CHARACTERISTIC] != nil)else{return}
//            connectPeripheral.setNotifyValue(true, for: charDictionary[C001_CHARACTERISTIC]!)
        }
    }
    
    /* 解配對 */
    func unpair() {
        let user = UserDefaults.standard
        user.removeObject(forKey: "KEY_PERIPHERAL_UUID")
        user.synchronize()
        guard connectPeripheral != nil else {
            return
        }
        centralManager.cancelPeripheralConnection(connectPeripheral)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        print("*******************************************************")
        
        if error != nil {
            print("\(error.debugDescription)")
            return
        }
        if ((characteristic.descriptors) != nil) {
            
            for x in characteristic.descriptors!{
                let descript = x as CBDescriptor!
                print("function name: DidDiscoverDescriptorForChar \(String(describing: descript?.description))")
            }
           
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
print("--------send-------")
        print()
    }

    @IBAction func Serch(_ sender: Any) {
        unpair()
        bl=true
        connectblename=""
        bles.removeAll()
        tb.reloadData()
        centralManager.scanForPeripherals(withServices: nil, options: nil)

    }
}

