//
//  ViewController.swift
//  YQNetworking
//
//  Created by wyqpadding@gmail.com on 02/25/2021.
//  Copyright (c) 2021 wyqpadding@gmail.com. All rights reserved.
//

import UIKit
import YQNetworking

struct Model: Decodable {
    let date: Date
}

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        Network.login.request(success: { _ in
//
//        }, failure: { _ in
//
//        })
//
//        Network.login.request(Int.self) { _ in
//
//        } failure: { _ in
//        }
//
//        Network.login.request(callbackQueue: nil, progress: nil, cachedResult: { _ in
//
//        }, successMap: { _ in
//
//        }, failure: { _ in
//
//        })
//
        NetworkProvider.shared.failureMap = { error in
            print(error)
            if error is NetworkErrorCompatical {
                return error
            } else {
                return CustomNetworkError("我是自己定义的错误")
            }
        }
        Network.model.request(Model.self) { _ in
            
        } failure: { error in
            print(error)
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
