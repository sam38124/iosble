//
//  blecell.swift
//  hh
//
//  Created by 王建智 on 2019/4/26.
//  Copyright © 2019 王建智. All rights reserved.
//

import UIKit

class blecell: UITableViewCell {
    var controller:ViewController?=nil
    var canconnect=true
    @IBOutlet var name: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func connect(_ sender: Any) {
        if(canconnect){
            print("開始連線")
            controller?.connectblename=name.text!
            controller!.centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
        

    }
}
