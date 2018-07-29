//
//  GameScene.swift
//  FlappyBird
//
//  Created by 黒木龍介 on 2018/07/13.
//  Copyright © 2018年 Ryusuke.Kuroki. All rights reserved.
//

import SpriteKit
import AVFoundation

//SKSceneの設定----------------------------------------------------------------------------
class GameScene: SKScene, SKPhysicsContactDelegate {
    var scrollNode:SKNode!
    var wallNode: SKNode!
    var bird: SKSpriteNode!
    var itemNode: SKNode!
    var ItemGet: AVAudioPlayer?
    
    //衝突判定カテゴリー
    // << という演算子はビットをずらすことができる
    //衝突判定カテゴリーでは、32桁のどこに1があるかを見て衝突相手を判断する
    let birdCategory: UInt32 = 1 << 0      //0...000001
    let groundCategory: UInt32 = 1 << 1    //0...000010
    let wallCategory: UInt32 = 1 << 2      //0...000100
    let scoreCategory: UInt32 = 1 << 3     //0...001000
    let itemCategory: UInt32 = 1 << 4      //0...010000
    let scoreItemCategory: UInt32 = 1 << 5 //0...100000
    
    //スコア
    //スコアは、上と下の壁の間に見えない物体を用意し、それに衝突した時にくぐったと判断してスコアをカウントアップする
    var score = 0
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    //スコアを保存する
    let userDefaults:UserDefaults = UserDefaults.standard
    
    //アイテム取得に関するスコアの設定
    var scoreItem = 0
    var scoreItemLabelNode:SKLabelNode!
    
//SKView上にシーンが表示された時に呼ばれるメソッド------------------------------------------------
//ゲーム画面(SKSceneクラスを継承したクラス)が表示される時に呼ばれるメソッド「didMove(to:)」
    override func didMove(to view: SKView) {
        
        //重力を設定
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -4.0)
        physicsWorld.contactDelegate = self

        //背景色を設定する 今回は青空の色で
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)

        //スクロールするスプライトの親ノード
        //ゲームオーバー時にスクロールを一括で止めることを目的として親のノードを作成
        scrollNode = SKNode()
        addChild(scrollNode)
        
        //壁用のノードを設定する
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        //アイテム用のノードを設定する
        itemNode = SKNode()
        scrollNode.addChild(itemNode)
        
        //各種スプライトを生成する処理をメソッドに分割する
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupScoreLabel()
        setupItem()
    }
//----------------------------------------------------------------------------------------
    
    
//地面をスクロールさせるメソッド「setupGround」を設定する------------------------------------------
    func setupGround() {
        //地面の画像を読み込む
        //最初にSKTextureクラスを作成、SpriteKitでは表示する画像をSKTextureで扱う
        let groundTexture = SKTexture(imageNamed: "ground")
        //多少画像が荒くなってでも処理速度を高めるための設定。ここで「.linear」を設定すると画質を優先できる
        groundTexture.filteringMode = .nearest
        
        //地面をスクロールして表示させるために必要な枚数を計算してneedNumberに
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        //スクロールするアクションを三段階に分けて作成
        //左方向に画像一枚分スクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5.0)
        //元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y:0, duration: 0.0)
        //左にスクロール->元の位置->左にスクロールと無限に切り替えるアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        //テクスチャを指定して「地面」スプライトを作成する
        //スプライトとは、コンピュータ処理の負荷を上げずに高速に画像を描画するシステムであり「画像を表示するためのもの」
        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: groundTexture)
            
            //「地面スプライト」の表示する位置を指定する
            //指定する箇所はNodeの中心となる
            //ちなみに、SpriteKitの座標系は左下が原点
            sprite.position = CGPoint(
                x: groundTexture.size().width * (CGFloat(i) + 0.5),
                y: groundTexture.size().width * 0.15
            )
            
            //スプライトにアクションを設定する
            sprite.run(repeatScrollGround)
            
            //スプライトに物理演算を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            //衝突のカテゴリー設定
            sprite.physicsBody?.categoryBitMask = groundCategory
            
            //重力の影響も受けず、衝突の時に動かないようにする
            sprite.physicsBody?.isDynamic = false
            
            //スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
//----------------------------------------------------------------------------------------
    
    
//雲をスクロールさせるメソッド「setupCloud」を設定する--------------------------------------------
    func setupCloud() {
        //雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        //必要な枚数を計算する
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        //スクロールするアクションを作成
        //左方向に画像一枚分するロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20.0)
        //元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        //左にスクロール->元の位置->左にスクロールを無限に切り替えるアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        //スプライトを配置する
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 //一番後ろになるようにする
            
            //スプリトの表示する位置を指定する
            sprite.position = CGPoint(
                x: cloudTexture.size().width * (CGFloat(i) + 0.5),
                y: self.size.height - cloudTexture.size().height * 0.5
            )
            
            //スプライトにアニメーションを設定する
            sprite.run(repeatScrollCloud)
            
            //スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
//----------------------------------------------------------------------------------------
    
    
//アイテムに関するメソッド--------------------------------------------------------------------
    func setupItem()  {
        //アイテムの画像を読み込む
        let itemTexture = SKTexture(imageNamed: "apple")
        itemTexture.filteringMode = .linear
        
        //移動する距離を計算
        let itemMovingDistance = CGFloat(self.frame.width + itemTexture.size().width)
        //画面外まで移動するアクションを作成
        let moveItem = SKAction.moveBy(x: -itemMovingDistance, y: 0, duration: 4.0)
        //自身を取り除くアクションを作成
        let removeItem = SKAction.removeFromParent()
        //２つのアニメーションを順に実行するアクションを作成
        let itemAnimation = SKAction.sequence([moveItem, removeItem])
        
        //アイテムを生成するアクションを作成
        let createItemAnimation = SKAction.run ({
            //アイテム関連のノードを乗せるためのノードを作成
            let item = SKNode()
            item.position = CGPoint(x: self.frame.width + itemTexture.size().width / 2, y: 0)
            item.zPosition = -50.0
            
            //画面のY軸の中央値
            let center_y = self.frame.size.height / 1.5
            //アイテムのY座標を上下ランダムにさせるときの最大値
            let random_y_range = self.frame.size.height / 2
            //下の壁のY軸の下限
            let under_item_lowest_y = UInt32(center_y - itemTexture.size().height / 2 - random_y_range / 2)
            //1〜random_y_rangeまでのランダムな整数を生成
            let random_y = arc4random_uniform( UInt32(random_y_range) )
            //Y軸の下限にランダムな値を足して、下の壁のY座標を決定
            let under_item_y = CGFloat(under_item_lowest_y + random_y)
            
            //アイテムを生成
            let item_apple = SKSpriteNode(texture: itemTexture)
            item_apple.position = CGPoint(x: -120 , y: under_item_y)
            
            //スプライトに物理演算を設定する
            item_apple.physicsBody = SKPhysicsBody(circleOfRadius: item_apple.size.height / 2.0)
            item_apple.physicsBody?.categoryBitMask = self.itemCategory
            
            //重力の影響を受けず、衝突の時に動かないように設定する
            item_apple.physicsBody?.isDynamic = false
            
            item.addChild(item_apple)
            
            //アイテムとの衝突判定のための設定
            item_apple.physicsBody?.categoryBitMask = self.scoreItemCategory
            item_apple.physicsBody?.contactTestBitMask = self.birdCategory
            
            item.run(itemAnimation)
            
            self.itemNode.addChild(item)
        })
        
        //次のアイテム作成までの待ち時間のアクションを作成
        let item_appleAnimation = SKAction.wait(forDuration: 2)
        
        //アイテムを作成->待ち時間->アイテムを作成を無限に切り替えるアクションを作成
        let repeatForeverAnimation_item = SKAction.repeatForever(SKAction.sequence([createItemAnimation, item_appleAnimation]))
        
        itemNode.run(repeatForeverAnimation_item)
    }
//---------------------------------------------------------------------------------------
    
//壁をスクロールさせる「setupWall」メソッドを設定する---------------------------------------------
    func setupWall() {
        //壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        //移動する距離を計算
        let movingDistance = CGFloat(self.frame.width + wallTexture.size().width)
        //画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4.0)
        //自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        //2つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        //壁を生成するアクションを作成
        let createWallAnimation = SKAction.run ({
            //壁関連のノードを乗せるためのノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0.0)
            wall.zPosition = -50.0 //雲より手前、地面より奥
            
            //画面のY軸の中央値
            let center_y = self.frame.size.height / 2
            //壁のY座標を上下ランダムにさせるときの最大値
            let random_y_range = self.frame.size.height / 4
            //下の壁のY軸の下限
            let under_wall_lowest_y = UInt32(center_y - wallTexture.size().height / 2 - random_y_range / 2)
            //1〜random_y_rangeまでのランダムな整数を生成
            let random_y = arc4random_uniform( UInt32(random_y_range) )
            //Y軸の下限にランダムな値を足して、下の壁のY座標を決定
            let under_wall_y = CGFloat(under_wall_lowest_y + random_y)
            
            //キャラが通り抜ける隙間の長さ
            let slit_length = self.frame.size.height / 6
            
            //下の壁を生成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0.0, y: under_wall_y)
            
            //スプライトに物理演算を設定する
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            
            //重力の影響を受けず、衝突の時に動かないように設定する
            under.physicsBody?.isDynamic = false
            
            wall.addChild(under)
            
            //上側の壁を生成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0.0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            //スプライトに物理演算を設定する
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            
            //重力の影響を受けず衝突の時に動かないように設定する
            upper.physicsBody?.isDynamic = false
            
            wall.addChild(upper)
            
            //スコアアップ用のノード
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + self.bird.size.width / 2, y: self.frame.height / 2.0)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            
            wall.addChild(scoreNode)
            
            wall.run(wallAnimation)
            
            self.wallNode.addChild(wall)
        })
        
        //次の壁作成までの待ち時間のアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        //壁を作成->待ち時間->壁を作成を無限に切り替えるアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
    }
//----------------------------------------------------------------------------------------
    
    
//自分のキャラである鳥を設定する----------------------------------------------------------------
    func setupBird() {
        //鳥の画像を2種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        //二種類のテクスチャを交互に変更するアニメーションを作成
        let texturesAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texturesAnimation)
        
        //スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        
        //物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        
        //衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false
        
        //衝突のカテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | scoreItemCategory
        
        //アニメーションを作成
        bird.run(flap)
        
        //スプライトを追加する
        addChild(bird)
    }
//----------------------------------------------------------------------------------------
    
    
//画面をタップした時に取りを上方向に動かす--------------------------------------------------------
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0 {
        //鳥の速度を0にする
        bird.physicsBody?.velocity = CGVector.zero
        
        //鳥に縦方向の力を与える
        bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
            
        } else if bird.speed == 0 {
            restart()
        }
    }
//----------------------------------------------------------------------------------------
    
    
//衝突した時に呼ばれるメソッド-----------------------------------------------------------------
    // SKPhysicsContactDelegateのメソッド。衝突したときに呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        // ゲームオーバーのときは何もしない
        if scrollNode.speed <= 0 {
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            // スコア用の物体と衝突した
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"    // ←追加
            
            // ベストスコア更新か確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
        } else if (contact.bodyA.categoryBitMask & scoreItemCategory) == scoreItemCategory || (contact.bodyB.categoryBitMask & scoreItemCategory) == scoreItemCategory {
            //アイテムと衝突し、アイテムを獲得した
            print("ItemScore Up")
            scoreItem += 1
            scoreItemLabelNode.text = "Item Score:\(scoreItem)"
            
            //bodyBがアイテムであるので、bodyBを消す
            //print(contact.bodyB.node!) - bodyBに割り当てられているのがアイテム(アップル)であることを確認
            contact.bodyB.node!.removeFromParent()
            
            //この時、音を鳴らす
            if var sound = NSDataAsset(name: "ItemGet") {
                ItemGet = try? AVAudioPlayer(data: sound.data)
                ItemGet?.play()
                print("ItemGet sounds")
            }
            
            //アイテム3個ごとにスコアを2倍へ
            if scoreItem >= 3 {
                score = score * 2
                scoreItem = 0
                print("reset scoreItem")
            }
            
        } else {
            // 壁か地面と衝突した
            print("GameOver")
            
            // スクロールを停止させる
            scrollNode.speed = 0
            
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration:1)
            bird.run(roll, completion:{
                self.bird.speed = 0
            })
        }
    }
//----------------------------------------------------------------------------------------
    
    
//衝突後の回転のアクション後、リスタートする------------------------------------------------------
    func restart() {
        score = 0
        scoreItem = 0
        scoreLabelNode.text = String("Score:\(score)")
        scoreItemLabelNode.text = String("Item Score:\(scoreItem)")
        
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0.0
        
        wallNode.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
    }
//----------------------------------------------------------------------------------------
    
    
//音を出すための関数-------------------------------------------------------------------------
    func ItemSound() {
        if let sound = NSDataAsset(name: "ItemGet") {
            ItemGet = try? AVAudioPlayer(data: sound.data)
            ItemGet?.play()
            print("ItemGet sounds")
        }
    }
//----------------------------------------------------------------------------------------
    
    
//スコア表示に関するクラス---------------------------------------------------------------------
    func setupScoreLabel() {
        //スコア
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 30)
        scoreLabelNode.zPosition = 100
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        //アイテムスコア
        scoreItem = 0
        scoreItemLabelNode = SKLabelNode()
        scoreItemLabelNode.fontColor = UIColor.black
        scoreItemLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreItemLabelNode.zPosition = 100
        scoreItemLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreItemLabelNode.text = "Item Score:\(scoreItem)"
        self.addChild(scoreItemLabelNode)
        
        //ベストスコア
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100 // 一番手前に表示する
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
    }
//----------------------------------------------------------------------------------------
}
