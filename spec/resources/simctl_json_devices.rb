module RunLoop
  module RSpec
    module Simctl

      SIMCTL_DEVICE_JSON_XCODE7 = %q[{"devices" : {
    "iOS 8.1" : [
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 4s",
        "udid" : "945BD341-62FC-43F1-9663-4DFA3E0D344B"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 5",
        "udid" : "0B81AC00-1971-4CEB-8B14-9BE00C56F0E3"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 5s",
        "udid" : "7291426B-DA71-4821-B33D-7F8B0A0758CF"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 6",
        "udid" : "F1D457B9-2735-4A0A-B789-029C91F8EB09"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 6 Plus",
        "udid" : "09A7F497-3676-4BB1-9039-37D45AB1EC04"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad 2",
        "udid" : "F53A23B6-8784-4E4B-AB40-D03BCB9830C1"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad Retina",
        "udid" : "4BC8B97A-21E0-44B3-B14D-D6F9AF39ED30"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad Air",
        "udid" : "93C66287-B89D-44CF-AC78-6ED07478E0E6"
      },
      {
        "state" : "Shutdown",
        "availability" : " (unavailable, device type profile not found)",
        "name" : "Resizable iPad",
        "udid" : "CE31FF59-7F6E-4109-AE40-3495CA22905E"
      },
      {
        "state" : "Shutdown",
        "availability" : " (unavailable, device type profile not found)",
        "name" : "Resizable iPhone",
        "udid" : "36451928-B193-463B-98A6-38C99FC1051D"
      }
    ],
    "watchOS 2.2" : [
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "Apple Watch - 38mm",
        "udid" : "81D90B1B-4EDE-4D46-88CC-A590D2AA7F20"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "Apple Watch - 42mm",
        "udid" : "A484A0A8-6207-4F02-8229-D465FE822450"
      }
    ],
    "iOS 9.0" : [
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 4s",
        "udid" : "DE305A3C-0F13-4D7B-A07D-7694FD851973"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 5",
        "udid" : "7861F740-0550-48FF-B998-25A5CDE454CF"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 5s",
        "udid" : "135E433F-CC1F-451B-B05C-0B2F09822814"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 6",
        "udid" : "D2888512-6233-45A5-AD90-AC82B05B49D4"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 6 Plus",
        "udid" : "843557E9-E939-483D-8C4E-1F575C0809B7"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 6s",
        "udid" : "A399F57A-BBFB-4FAF-B754-C220B1A07C28"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 6s Plus",
        "udid" : "40EB1794-0CF0-4598-B77B-E3F09A38A6D3"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad 2",
        "udid" : "698876F2-031D-49B8-8C72-F126728D07BF"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad Retina",
        "udid" : "FDB0E70A-52BD-4534-91E5-56D8B5A8D827"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad Air",
        "udid" : "CD1C42E5-0F65-4C5C-923B-00C01854692E"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad Air 2",
        "udid" : "C5171C9A-7EDF-43DC-8A28-1456FC065FDD"
      }
    ],
    "iOS 8.3" : [
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 4s",
        "udid" : "7A21C78E-159F-4022-8002-E0DDFEC8B00E"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 5",
        "udid" : "10721F48-AC27-4E25-B1EA-28ED3F344D35"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 5s",
        "udid" : "33E644E8-096B-4766-A957-4B34FB18DC48"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 6",
        "udid" : "5C2EDC83-711C-47FC-84D5-A451FDA4BA5F"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 6 Plus",
        "udid" : "7C00CF32-4F9A-4B66-96F6-3D6A41187C0E"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad 2",
        "udid" : "AB8155B6-97A2-4425-BA0A-E5CA002A7C36"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad Retina",
        "udid" : "FDD74F16-6FDC-4D4D-8F4E-BFF65FA48EAC"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad Air",
        "udid" : "994F236A-87AC-45F6-A3AF-8F2739BE8F2F"
      },
      {
        "state" : "Shutdown",
        "availability" : " (unavailable, device type profile not found)",
        "name" : "Resizable iPad",
        "udid" : "FC760369-63A5-4BC9-A1F0-3170956FB114"
      },
      {
        "state" : "Shutdown",
        "availability" : " (unavailable, device type profile not found)",
        "name" : "Resizable iPhone",
        "udid" : "B3D3D912-C110-4B73-B5D5-76AF76FB3EFB"
      }
    ],
    "iOS 7.1" : [
      {
        "state" : "Shutdown",
        "availability" : " (unavailable, Mac OS X 10.11.4 is not supported)",
        "name" : "iPhone 4s",
        "udid" : "02685B8F-16F8-4505-A2C5-BD7DC199F718"
      },
      {
        "state" : "Shutdown",
        "availability" : " (unavailable, Mac OS X 10.11.4 is not supported)",
        "name" : "iPhone 5",
        "udid" : "F2D8D832-1BE4-4918-A557-30BB36639A66"
      },
      {
        "state" : "Shutdown",
        "availability" : " (unavailable, Mac OS X 10.11.4 is not supported)",
        "name" : "iPhone 5s",
        "udid" : "F1E72700-047F-4A9E-B73F-34488BC07676"
      },
      {
        "state" : "Shutdown",
        "availability" : " (unavailable, Mac OS X 10.11.4 is not supported)",
        "name" : "iPad 2",
        "udid" : "9D82A8EB-EEBA-4F67-8269-A95A0B9D7B5D"
      },
      {
        "state" : "Shutdown",
        "availability" : " (unavailable, Mac OS X 10.11.4 is not supported)",
        "name" : "iPad Retina",
        "udid" : "2C80406F-CEFE-486E-AC2C-FF5BBFADDAF0"
      },
      {
        "state" : "Shutdown",
        "availability" : " (unavailable, Mac OS X 10.11.4 is not supported)",
        "name" : "iPad Air",
        "udid" : "706328C2-DCA2-4EE3-B082-448C8CF30468"
      }
    ],
    "iOS 9.2" : [
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 4s",
        "udid" : "FAC37150-B89C-456C-80F4-606CDF1B0D64"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 5",
        "udid" : "C9E7A3AD-4E8D-4BCC-AF99-1B6CEECA4309"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 5s",
        "udid" : "DF9753BD-B3E4-4C68-94A3-27DCD8221A62"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 6",
        "udid" : "59FE6A5A-9245-480F-995F-8BEAF7A57506"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 6 Plus",
        "udid" : "833460CE-326B-412C-8FDC-BC39DAAE5C3F"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 6s",
        "udid" : "9CEEC4D2-146E-4901-9910-CC9D00C3DED2"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 6s Plus",
        "udid" : "F938CE2D-29B8-4772-AAD2-547BAEAA768E"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad 2",
        "udid" : "7F9915B0-A9C5-492F-BE40-C8F7DF59B9B0"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad Retina",
        "udid" : "262C0D67-B345-4021-A306-61FA6370FCF0"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad Air",
        "udid" : "A818F61B-436E-485B-89BB-41CB391BB437"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad Air 2",
        "udid" : "7D9894E5-5BC2-4F78-935B-BF6D1C50778C"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad Pro",
        "udid" : "E01118BC-4DE5-47C7-912B-FC127BF01A9C"
      }
    ],
    "tvOS 9.0" : [
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "Apple TV 1080p",
        "udid" : "D6875A98-2C0E-4138-85EF-841025A54DE0"
      }
    ],
    "iOS 8.2" : [
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 4s",
        "udid" : "C8C478EF-4C18-436E-87F8-7FBEEDC6755F"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 5",
        "udid" : "6A145CDE-7BE5-4A14-A6E9-1AE6F4E4E6B2"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 5s",
        "udid" : "CBE20521-E830-4E4A-8E3F-D0D476FBB983"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 6",
        "udid" : "01E95D27-5248-49DB-98A3-B4661C695764"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 6 Plus",
        "udid" : "3B15DDE0-CA62-4928-B6BF-7AC6914EE158"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad 2",
        "udid" : "058B5619-94DF-4BFE-9FA1-BF50225F6A79"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad Retina",
        "udid" : "3A4BB54E-AFC2-40C9-8118-9A5706E52421"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad Air",
        "udid" : "4232530F-356D-428A-98BD-A440891263D3"
      },
      {
        "state" : "Shutdown",
        "availability" : " (unavailable, device type profile not found)",
        "name" : "Resizable iPad",
        "udid" : "AE7254BF-CAE6-4EC0-B4AA-5FE48364E7A4"
      },
      {
        "state" : "Shutdown",
        "availability" : " (unavailable, device type profile not found)",
        "name" : "Resizable iPhone",
        "udid" : "A5E25EE5-9D6B-44A8-A168-55338FDC21ED"
      }
    ],
    "tvOS 9.1" : [
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "Apple TV 1080p",
        "udid" : "D220FC91-6ACA-4BD4-A004-28D78DDB8198"
      }
    ],
    "iOS 9.1" : [
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 4s",
        "udid" : "E8D127B8-7FA9-4AE6-98F1-B86DF28B2005"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 5",
        "udid" : "C68D52E0-83DF-4A3A-9478-83CF688739BC"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 5s",
        "udid" : "30C1D8B0-EA3D-4AE7-B5F3-4EB169F4908F"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 6",
        "udid" : "6B7E83D3-4CB3-4882-B0C2-B3441F129B40"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 6 Plus",
        "udid" : "331E4E54-A655-4AB4-BEED-744590C33D99"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 6s",
        "udid" : "41A530E0-E5C1-44EE-B6BF-0BEC642F01BE"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 6s Plus",
        "udid" : "6E8B423D-8EA3-44BB-B38C-924E51449BF4"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad 2",
        "udid" : "0EACBA43-34C5-4B73-9DDC-75FDF97FEAAF"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad Retina",
        "udid" : "0D0F5457-0C77-4AF2-A0B5-EE2CE6A821B4"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad Air",
        "udid" : "1824DB1A-6F4B-432D-9BBA-D1B19CAB9E11"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad Air 2",
        "udid" : "FB96E4FA-C621-4D58-B6D4-AC665CAA0714"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad Pro",
        "udid" : "A2BDDFF2-0523-4954-8698-79E27DA0852C"
      }
    ],
    "watchOS 2.0" : [
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "Apple Watch - 38mm",
        "udid" : "9F634666-73AC-429D-B214-259106CDD672"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "Apple Watch - 38mm",
        "udid" : "5D61096C-FD43-4E2D-A45E-1F37AD0D1B3B"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "Apple Watch - 42mm",
        "udid" : "3641C252-E6F8-4972-9724-03142ACEDC62"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "Apple Watch - 42mm",
        "udid" : "2577AAE3-14F5-48FC-9E69-4E505F2BF552"
      }
    ],
    "tvOS 9.2" : [
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "Apple TV 1080p",
        "udid" : "C339010B-4D7A-499F-A760-B101D581F7A4"
      }
    ],
    "iOS 8.4" : [
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 4s",
        "udid" : "A51BBC5E-424C-46F4-9D3C-E241E2058057"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 5",
        "udid" : "57B266FC-A180-4420-B924-DEE81351D738"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 5s",
        "udid" : "55DA4317-E3CB-47B0-B589-117B320A18A3"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 6",
        "udid" : "2712BF81-ABDE-4C87-B81B-8D7F46178FD6"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 6 Plus",
        "udid" : "09E906BD-D905-4D7D-BCC8-6402E7875A11"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad 2",
        "udid" : "EA28BCDB-A02B-4D1E-973E-A492E5A3C432"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad Retina",
        "udid" : "FB1733DB-EE06-4124-A202-FBC0FD8BA233"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad Air",
        "udid" : "272F9558-B17A-4D47-9F6E-B72A85893707"
      },
      {
        "state" : "Shutdown",
        "availability" : " (unavailable, device type profile not found)",
        "name" : "Resizable iPad",
        "udid" : "9A55C34F-39A3-4DE9-8FE9-DDD261CEBDF8"
      },
      {
        "state" : "Shutdown",
        "availability" : " (unavailable, device type profile not found)",
        "name" : "Resizable iPhone",
        "udid" : "44A612B6-2BA3-4067-8331-60C05D19DF1B"
      }
    ],
    "watchOS 2.1" : [
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "Apple Watch - 38mm",
        "udid" : "5A95E076-D4CF-452C-A1B1-2DF5EB04BD5A"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "Apple Watch - 42mm",
        "udid" : "41333BDA-5EF2-46CC-BFC2-1D89EE58783F"
      }
    ],
    "iOS 9.3" : [
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 4s",
        "udid" : "B20B6D90-0E8C-4A0B-882F-AF95228B4935"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 5",
        "udid" : "D1B22B9C-F105-4DF0-8FA3-7AE41E212A9D"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 5s",
        "udid" : "C5DD3499-C4FC-43D1-88AA-9C5B3FBD70BE"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 6",
        "udid" : "BD2010F9-401C-4E56-AE8A-ECB7CD3370D8"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 6 Plus",
        "udid" : "D6AFEDFE-2E02-4A33-AEC8-740053DDC6DE"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 6s",
        "udid" : "F6EF1FA5-1C3F-465E-8B29-70C293DE0F66"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPhone 6s Plus",
        "udid" : "DEFAEB74-D97E-4D2F-8A42-DEB6191B2D39"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad 2",
        "udid" : "F93D2C4A-4000-4C36-B1FE-573BD00F616C"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad Retina",
        "udid" : "4768C1E7-28E2-40D5-8CC1-0B6A6186EA61"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad Air",
        "udid" : "6D3AF312-D888-4023-B7FE-1B55A927F9A3"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad Air 2",
        "udid" : "B78EA4FA-6994-44C5-B0FE-428ECA717463"
      },
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "iPad Pro",
        "udid" : "ADE8D83B-5DE9-4D41-BD6E-12752DC1873A"
      }
    ]
  }
}]
    end
  end
end
