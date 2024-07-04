//
//  ViewController.swift
//  TagTextFieldApp
//
//  Created by nakamori.emiri on 2024/06/22.
//

import UIKit

class ViewController: UIViewController, UITextViewDelegate {
    
    private let textView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.layer.borderColor = UIColor.gray.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 5
        return textView
    }()
    
    private let tagScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    private let tagStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 10
        return stackView
    }()
    
    private var tags: [Tag] = [
        Tag(id: 1, text: "嘔吐", color: .red),
        Tag(id: 2, text: "うんち", color: .red),
        Tag(id: 3, text: "ご飯", color: .orange),
        Tag(id: 4, text: "薬", color: .orange),
        Tag(id: 5, text: "発作", color: .red)
    ]
    
    // サーバーに送る文字列のモデル　復元の仕方を話し合う
    private var dataTags: [Tag] = [
        Tag(id: 1, text: "$嘔吐$", color: .red),
        Tag(id: 2, text: "$うんち$", color: .red),
        Tag(id: 3, text: "$ご飯$", color: .orange),
        Tag(id: 4, text: "$薬$", color: .orange),
        Tag(id: 5, text: "$発作$", color: .red)
    ]

    private var insertedTips: [NSRange] = []
    var allTipText: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTagButtons()
    }
    
    private func setupUI() {
        view.addSubview(textView)
        view.addSubview(tagScrollView)
        tagScrollView.addSubview(tagStackView)
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        tagScrollView.translatesAutoresizingMaskIntoConstraints = false
        tagStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.heightAnchor.constraint(equalToConstant: 200),
            
            tagScrollView.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 20),
            tagScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tagScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tagScrollView.heightAnchor.constraint(equalToConstant: 50),
            
            tagStackView.topAnchor.constraint(equalTo: tagScrollView.topAnchor),
            tagStackView.leadingAnchor.constraint(equalTo: tagScrollView.leadingAnchor, constant: 20),
            tagStackView.trailingAnchor.constraint(equalTo: tagScrollView.trailingAnchor, constant: -20),
            tagStackView.bottomAnchor.constraint(equalTo: tagScrollView.bottomAnchor)
        ])
        
        textView.delegate = self
    }
    
    private func setupTagButtons() {
        for tag in tags {
            let button = UIButton(type: .system)
            button.setTitle(tag.text, for: .normal)
            button.backgroundColor = tag.color
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 15
            if #available(iOS 15.0, *) {
                // iOS 15以降ではcontentInsetsを使用する
                button.configuration = UIButton.Configuration.plain()
                button.configuration?.titlePadding = 10
                button.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
            } else {
                // iOS 12以下ではcontentEdgeInsetsを使用する
                button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
            }
            button.addTarget(self, action: #selector(tagButtonTapped(_:)), for: .touchUpInside)
            tagStackView.addArrangedSubview(button)
        }
    }
    
    @objc private func tagButtonTapped(_ sender: UIButton) {
        guard let tagText = sender.titleLabel?.text else { return }
        insertTag(tagText)
    }
    
    private func insertTag(_ tagText: String) {
        let tag = tags.first { $0.text == tagText }
        
        // UILabel を作成して角丸の背景を持つビューを準備する
        let label = UILabel()
        label.text = tagText
        label.backgroundColor = tag?.color ?? .clear
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        let paddedFrame = label.frame.inset(by: UIEdgeInsets(top: 20, left: 30, bottom: 5, right: 20))
        label.frame = paddedFrame
        
        // UILabel を画像に変換する
        let renderer = UIGraphicsImageRenderer(size: label.bounds.size)
        let image = renderer.image { _ in
            label.layer.render(in: UIGraphicsGetCurrentContext()!)
        }
        
        guard let filterdTag = tags.first(where: { $0.text == tagText }) else {
            return
        }
        let tagFromServer = "$\(filterdTag.text)$"
        
        let attachment = NSTextAttachment()
        attachment.image = image
        let testIDKey = NSAttributedString.Key(rawValue: "testID")
        let tip = NSMutableAttributedString(string: "\(UnicodeScalar(NSTextAttachment.character)!)", attributes: [
            testIDKey: tagFromServer, .attachment: attachment
        ])
        
        // 挿入するテキストの前後に1pxのスペースを追加する
        let spaceBefore = NSAttributedString(string: " ", attributes: [.kern: 1])
        let spaceAfter = NSAttributedString(string: " ", attributes: [.kern: 1])

        // 挿入ポイントを取得する
        let insertionPoint = textView.selectedRange.location
        
        // attributedText を編集する
        let mutableAttributedString = NSMutableAttributedString(attributedString: textView.attributedText)
        mutableAttributedString.insert(tip, at: insertionPoint)
        
        mutableAttributedString.insert(spaceBefore, at: insertionPoint)
        mutableAttributedString.append(spaceAfter)
        
        textView.attributedText = mutableAttributedString
        
        // 挿入したタグの範囲を記録する（空白を含む）
        insertedTips.append(NSRange(location: insertionPoint, length: tagText.count + 2))

        // カーソルを移動する
        textView.selectedRange = NSRange(location: insertionPoint + tagText.count + 2, length: 0)
        
        
        let range = NSRange(location: 0, length: mutableAttributedString.string.count)
        allTipText = []
        // Custom Keyから値を取り出す
        mutableAttributedString.enumerateAttribute(testIDKey, in: range) { result, resultRange, _ in
            guard let result = result as? String else { return }
            
            allTipText.append(result)
        }
        
    }

    
    func textViewDidChange(_ textView: UITextView) {
        
        let currentTextView = NSMutableAttributedString(attributedString: textView.attributedText)
        let testIDKey = NSAttributedString.Key(rawValue: "testID")
        let range = NSRange(location: 0, length: currentTextView.string.count)
        currentTextView.enumerateAttribute(testIDKey, in: range) { result, resultRange, _ in
            guard let result = result as? String else { return }
            
            currentTextView.insert(NSAttributedString(string: result), at: resultRange.location)
        }
        
        print("全てのテキスト:", currentTextView.string)
        print("チップ全部:", allTipText)
    }

}

struct Tag {
    let id: Int
    let text: String
    let color: UIColor
}

#if DEBUG
import SwiftUI

struct ViewControllerPreview: PreviewProvider {
    static var previews: some View {
        ViewControllerRepresentable()
            .edgesIgnoringSafeArea(.all)
    }
}

struct ViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ViewController {
        return ViewController()
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
    }
}
#endif
