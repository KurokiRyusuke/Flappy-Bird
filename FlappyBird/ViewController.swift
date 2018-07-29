//
//  ViewController.swift
//  FlappyBird
//
//  Created by 黒木龍介 on 2018/07/12.
//  Copyright © 2018年 Ryusuke.Kuroki. All rights reserved.
//

import UIKit
//ゲームに使用するSpriteKitを使えるようにする
import SpriteKit


class ViewController: UIViewController {

    
//viewDidLoad-----------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //SKViewに型を変換する
        let skView = self.view as! SKView
        
        //FPSを表示する
        //FPS (Frame Per Second)とは、単位時間あたりに処理させるフレーム数の単位
        skView.showsFPS = true
        
        //ノードの数を表示する
        //ノードとは、ネットワーク上に接続されている機器のこと
        //ノード数が高いと処理が重たくなり、結果FPSが減少する。FPS値が下がると動きが悪くなりユーザーに嫌われやすい
        skView.showsNodeCount = true
        
        //skViewと同じサイズでSKsceneを作成する
        //SKSceneクラスを継承したGameScene.swiftを使用
        let scene = GameScene(size:skView.frame.size)
        
        //skViewにsceneを表示する
        //SKViewクラスのpresentScence()メソッドを使ってSKSceneを設定する
        skView.presentScene(scene)
    }
//----------------------------------------------------------------------------------------------
    
    
//MemoryWarning---------------------------------------------------------------------------------
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
//----------------------------------------------------------------------------------------------


//ステータスバーを消す------------------------------------------------------------------------------
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
//----------------------------------------------------------------------------------------------
}

