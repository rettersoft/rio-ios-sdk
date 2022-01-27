//
//  ViewController.swift
//  Rio
//
//  Created by Baran Baygan on 01/27/2022.
//  Copyright (c) 2022 Baran Baygan. All rights reserved.
//

import UIKit
import Rio

class ViewController: UIViewController {

    var rioObj:RioCloudObject?
    @IBOutlet weak var lblValue: UILabel!
    
    let rio = Rio.init(config: RioConfig(projectId: "15gs19h2ek"))
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        rio.delegate = self
        
//        rio.signInAnonymously()
        
        
//        rio.getCloudObject(with: RioCloudObjectOptions(classID: "Test")) { object in
//
//            print("InstanceId is \(object.instanceId)")
//
//            self.rioObj = object
//
//            self.rioObj?.state?.public.subscribe(onSuccess: { data in
//                if let data = data, let r = data["r"] {
//                    print("\(r)")
//                    self.lblValue.text = "\(r)"
//                }
//
//            }, onError: { err in
//
//            })
//
//        } onError: { error in
//
//        }
        
        
        

    }

    @IBAction func btnTapped(_ sender: Any) {
        
        self.rioObj?.call(with: RioCloudObjectOptions(method: "sayHello")) { resp in
            
            print("resp \(resp.body)")
            
        } onError: { error in
            
        }
        
    }
}

extension ViewController : RioClientDelegate {
    func rbsClient(client: Rio, authStatusChanged toStatus: RioClientAuthStatus) {
        print("Auth status \(toStatus)")
    }
}
