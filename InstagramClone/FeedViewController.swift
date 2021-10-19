//
//  FeedViewController.swift
//  InstagramClone
//
//  Created by Jacob on 10/13/21.
//

import UIKit
import Parse
import AlamofireImage
import MessageInputBar

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MessageInputBarDelegate{

    @IBOutlet weak var tableView: UITableView!
    
    let commentBar = MessageInputBar()
    var showsCommentBar = false // Toggles commentbar in canBecomeFirstResponder
    var posts = [PFObject]()
    var selectedPost: PFObject! // Used in didSelect to keep track of specific post for input message
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Adjusts the remarks on the input bar. End up having to add delegater to the class
        commentBar.inputTextView.placeholder = "Add a comment..."
        commentBar.sendButton.title = "Post"
        commentBar.delegate = self // Anything that can fire events (send)
        
        tableView.delegate = self
        tableView.dataSource = self
        // Do any additional setup after loading the view.
        
        //Input bars work with tableview natively
        tableView.keyboardDismissMode = .interactive // dissmisses keyboard by dragging it down
        
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillBeHidden(note:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillBeHidden(note: Notification) // Grab NotificationCenter, I want to observe event (Keyboard hides) call this function
    {
        commentBar.inputTextView.text = nil
        showsCommentBar = false
        becomeFirstResponder()
    }
    
    override var inputAccessoryView: UIView? // Commentbar magic apparently related to MenuInputBar pod
    {
        return commentBar
    }
    
    override var canBecomeFirstResponder: Bool // Same
    {
        return showsCommentBar // Keeps inputbar from showing as a default
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let query = PFQuery(className: "Posts")
        query.includeKeys(["author", "comments", "comments.author"])
        query.limit = 20
        
        query.findObjectsInBackground { (posts,error) in
            if posts != nil
            {
                self.posts = posts!
                self.tableView.reloadData()
            }
        }
    }
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
         //Create the comment
        let comment = PFObject(className: "Comments")
        comment["text"] = text // Comment text
        comment["post"] = selectedPost //The post it's linked to
        comment["author"] = PFUser.current()! //User of the comment

        selectedPost.add(comment, forKey: "comments")

        selectedPost.saveInBackground {(success, error) in
            if success
            {
                print("Comment saved")
                print(comment )
            }
            else
            {
                print("Error saving comment")
            }
        }
        
        tableView.reloadData()
        
        // Clear and dismiss the input bar
        commentBar.inputTextView.text = nil
        showsCommentBar = false
        becomeFirstResponder()
        commentBar.inputTextView.resignFirstResponder()
    
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

            let post = posts[section]
            let comments = (post["comments"] as? [PFObject]) ?? [] //Nil operator leftside if not nil, right side if nil
        
            return comments.count + 2 //Creates a table with the number of comments from the post, as well as for the image itself, and the addComment cell making it +2
                // was original just count of posts, but needs to include amount of comments now for each and add that in as well
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let post = posts[indexPath.section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        if indexPath.row == 0 { // If the row is the image/ caption
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCell
            
            let user = post["author"] as! PFUser
            cell.userNameLabel.text = user.username
            
            cell.captionLabel.text = post["caption"] as? String
            
            let imageFile = post["image"] as! PFFileObject
            let urlString = imageFile.url!
            let url = URL(string: urlString)!
            
            cell.photoView.af_setImage(withURL: url)
            
            return cell
        }
        else if indexPath.row <= comments.count // If within the bounds of the comments.
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentCell
            
            let comment = comments[indexPath.row - 1]
            cell.commentLabel.text = comment["text"] as? String
            
            let user = comment["author"] as! PFUser
            cell.nameLabel.text = user.username
            return cell
        }
        
        else // No longer in the bounds of comments so puts the AddCommentCell at the end.
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddCommentCell")!
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.section] // Posts in comments? Previous posts / comments from those posts. Each post will have own section in numberOfSections
        
        let comments = (post["comments"] as? [PFObject]) ?? [] // Comments come from database
        
        if indexPath.row == comments.count + 1
        {
            showsCommentBar = true
            becomeFirstResponder() // Evaluates and changes value
            commentBar.inputTextView.becomeFirstResponder()
            
            selectedPost = post
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func onLogoutButton(_ sender: Any) {
        PFUser.logOut()
        
        let main = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = main.instantiateViewController(identifier: "LoginViewController")
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let delegate = windowScene.delegate as? SceneDelegate else {return}
        
        delegate.window?.rootViewController = loginViewController
    }
}
