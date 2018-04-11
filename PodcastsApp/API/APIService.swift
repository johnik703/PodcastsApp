//
//  APIService.swift
//  PodcastsApp
//
//  Created by Nuno Pereira on 27/02/2018.
//  Copyright © 2018 Nuno Pereira. All rights reserved.
//

import UIKit
import Alamofire
import FeedKit

class APIService {
    
    static let shared = APIService()
    
    func fetchEpisodes(feedUrl: String, completionHandler: @escaping ([Episode]) -> ()) {
        
        let secureUrl = feedUrl.contains("https") ? feedUrl : feedUrl.replacingOccurrences(of: "http", with: "https")
        guard let url = URL(string: secureUrl) else {return}
        
        DispatchQueue.global(qos: .background).async {
            let parser = FeedParser(URL: url )
            
            parser?.parseAsync(result: { (result) in
                print("Successfully parse feed: ", result.isSuccess)
                
                if let err = result.error {
                    print("Failed to fetch RSSFeed: ", err)
                    return
                }
                
                guard let feed = result.rssFeed else {return}
                let episodes = feed.toEpisodes()
                
                completionHandler(episodes)
                
                //This switch test all possible result types
                //            switch result {
                //            case let .atom(feed):
                //                break
                //            case let .rss(feed):
                //                self.episodes = feed.toEpisodes()
                //
                //                DispatchQueue.main.async {
                //                    self.tableView.reloadData()
                //                }
                //                break
                //            case let .json(feed):
                //                break
                //            case let .failure(feed):
                //                break
                //
                //            }
            })
        }
    }
    
    func fetchPodcasts(searchText: String, completionHandler: @escaping ([Podcast]) -> ()) {
        
        let baseiTunesSearchURL = "https://itunes.apple.com/search"
        let parameters = ["term" : searchText, "media": "podcast"]
        
        Alamofire.request(baseiTunesSearchURL, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: nil).responseData { (dataResponse) in
            if let err = dataResponse.error {
                print("Failed to contact yahoo:", err)
                return
            }
            
            guard let data = dataResponse.data else {return}
            
            do {
                let searchResult = try JSONDecoder().decode(SearchResults.self, from: data)
                print("Results count: ", searchResult.resultCount)
                
                completionHandler(searchResult.results)
                
//                searchResult.results.forEach({ (podcast) in
//                    print("\(podcast.trackName ?? ""), \(podcast.artistName ?? "")")
//                })
            }
            catch let decodeErr {
                print("Failed to decode: ", decodeErr)
            }
        }
    }
}

struct SearchResults: Decodable {
    var resultCount: Int
    let results: [Podcast]
}
