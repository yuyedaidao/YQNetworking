//
//  ViewController.swift
//  YQNetworking
//
//  Created by wyqpadding@gmail.com on 02/25/2021.
//  Copyright (c) 2021 wyqpadding@gmail.com. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        Network.login.request(success: { _ in

        }, failure: { _ in

        })

        Network.login.request(Int.self) { _ in

        } failure: { _ in
        }

        Network.login.request(callbackQueue: nil, progress: nil, cachedResult: { _ in

        }, successMap: { _ in

        }, failure: { _ in

        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
