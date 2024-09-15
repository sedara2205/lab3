//
//  FeedViewController.swift
//  lab-insta-parse
//
//  Created by Harsha edara
//

import UIKit
import ParseSwift // Make sure ParseSwift is imported for querying Parse data

class FeedViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    private let refreshControl = UIRefreshControl()

    // Array to hold the posts retrieved from the server
    private var posts = [Post]() {
        didSet {
            // Reload table view data whenever the posts variable is updated
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up table view delegate and data source
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false

        // Set up refresh control for pull-to-refresh functionality
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Query posts when the view appears
        queryPosts()
    }

    // Function to query posts from the Parse database
    private func queryPosts(completion: (() -> Void)? = nil) {
        // Get the date for 24 hours ago
        let yesterdayDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        // Create a query to fetch posts, applying constraints for time and limit
        let query = Post.query()
            .include("user")  // Include related user data
            .order([.descending("createdAt")])  // Sort posts by the most recent
            .where("createdAt" >= yesterdayDate)  // Filter for posts created in the last 24 hours
            .limit(10)  // Limit the number of returned posts to a maximum of 10

        // Execute the query asynchronously
        query.find { [weak self] result in
            switch result {
            case .success(let posts):
                // Update the posts array with the fetched posts
                self?.posts = posts
            case .failure(let error):
                // Display an error message if the query fails
                self?.showAlert(description: error.localizedDescription)
            }

            // Call the completion handler (used to stop pull-to-refresh)
            completion?()
        }
    }

    // Function called when the log out button is tapped
    @IBAction func onLogOutTapped(_ sender: Any) {
        showConfirmLogoutAlert()
    }

    // Function called when the user performs a pull-to-refresh
    @objc private func onPullToRefresh() {
        refreshControl.beginRefreshing()
        queryPosts { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }

    // Helper function to show a confirmation alert for logging out
    private func showConfirmLogoutAlert() {
        let alertController = UIAlertController(
            title: "Log out of \(User.current?.username ?? "current account")?",
            message: nil,
            preferredStyle: .alert
        )
        let logOutAction = UIAlertAction(title: "Log out", style: .destructive) { _ in
            NotificationCenter.default.post(name: Notification.Name("logout"), object: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(logOutAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }

    // Helper function to display an alert with a given description
    private func showAlert(description: String) {
        let alertController = UIAlertController(title: "Error", message: description, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension FeedViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostCell else {
            return UITableViewCell()
        }
        // Configure the cell with the post data
        cell.configure(with: posts[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate

extension FeedViewController: UITableViewDelegate { }
