/*
Copyright 2025 pngdrift
SPDX-License-Identifier: Apache-2.0
*/
package beads {
	import org.apache.royale.core.IBead;
	import org.apache.royale.core.IStrand;
	import org.apache.royale.events.Event;

	public class LocalStorageCheckBoxStateBead implements IBead {

		public var key:String;

		private var checkBox:Object;

		public function set strand(value:IStrand):void {
			checkBox = value;
			if("selected" in checkBox) {
				key = key || checkBox.id;
				checkBox.selected = window.localStorage.getItem(key) == "true";
				checkBox.addEventListener(Event.CHANGE,onChange);
			}
			else {
				console.warn(checkBox.id,"does not have 'selected' property");
			}
		}

		private function onChange(event:Event):void {
			window.localStorage.setItem(key,String(checkBox.selected));
		}
	}
}
