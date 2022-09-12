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
    
    
    
    let rio = Rio.init(config: RioConfig(projectId: "15gs19h2ek", sslPinningEnabled: true, isLoggingEnabled: true, culture: "sl-TR"))
    
    var rioObj:RioCloudObject?
    
    @IBOutlet weak var lblValue: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rio.delegate = self

    }
    
    @IBAction func btnGetObjectTapped(_ sender: Any) {
        
        if rioObj != nil { return }
        
        
        
        
        rio.getCloudObject(with: RioCloudObjectOptions(classID: "Test")) { object in
            
            print("InstanceId is \(object.instanceId)")
            
            self.rioObj = object
            
//            self.rioObj?.call(with: RioCloudObjectOptions(, onSuccess: <#T##(RioCloudObjectResponse) -> Void#>, onError: <#T##(RioCloudObjectError) -> Void#>)
            
            self.rioObj?.state?.public.subscribe(onSuccess: { data in
                if let data = data, let r = data["r"] {
                    print("\(r)")
                    self.lblValue.text = "\(r)"
                }
                
            }, onError: { err in
                
            })
            
        } onError: { error in
            
        }
        
        
    }
    
    @IBAction func btnSayHelloTapped(_ sender: Any) {
        self.rioObj?.call(with: RioCloudObjectOptions(method: "sayHello", culture: "tr-TR")) { resp in
            
            print("resp \(resp.body)")
            
        } onError: { error in
            
        }
    }
    
    @IBAction func signOutTapped(_ sender: Any) {
        rio.signOut()
        rioObj = nil
    }
}

extension ViewController : RioClientDelegate {
    func rioClient(client: Rio, authStatusChanged toStatus: RioClientAuthStatus) {
        print("-- RioDebug in VC Auth status \(toStatus)")
    }
}
